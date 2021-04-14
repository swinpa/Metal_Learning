import Foundation
import Metal

public func defaultVertexFunctionNameForInputs(_ inputCount:UInt) -> String {
    switch inputCount {
    case 1:
        return "oneInputVertex"
    case 2:
        return "twoInputVertex"
    default:
        return "oneInputVertex"
    }
}

open class BasicOperation: ImageProcessingOperation {
    
    public let maximumInputs: UInt
    public let targets = TargetContainer()
    public let sources = SourceContainer()
    
    public var activatePassthroughOnNextFrame: Bool = false
    public var uniformSettings:ShaderUniformSettings
    
    /// 判断设备是否支持Metal渲染
    public var useMetalPerformanceShaders: Bool = false {
        didSet {
            if !sharedMetalRenderingDevice.metalPerformanceShadersAreSupported {
                print("Warning: Metal Performance Shaders are not supported on this device")
                useMetalPerformanceShaders = false
            }
        }
    }

    let renderPipelineState: MTLRenderPipelineState
    let operationName: String
    var inputTextures = [UInt:Texture]()
    let textureInputSemaphore = DispatchSemaphore(value:1)
    var useNormalizedTextureCoordinates = true
    var metalPerformanceShaderPathway: ((MTLCommandBuffer, [UInt:Texture], Texture) -> ())?

    public init(vertexFunctionName: String? = nil, fragmentFunctionName: String, numberOfInputs: UInt = 1, operationName: String = #file) {
        self.maximumInputs = numberOfInputs
        self.operationName = operationName
        
        let concreteVertexFunctionName = vertexFunctionName ?? defaultVertexFunctionNameForInputs(numberOfInputs)
        //根据 vertexFunctionName， fragmentFunctionName这些创建pipelineState
        
        let (pipelineState, lookupTable) = generateRenderPipelineState(device:sharedMetalRenderingDevice, vertexFunctionName:concreteVertexFunctionName, fragmentFunctionName:fragmentFunctionName, operationName:operationName)
        self.renderPipelineState = pipelineState
        self.uniformSettings = ShaderUniformSettings(uniformLookupTable:lookupTable)
    }
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt) {
        // TODO: Finish implementation later
    }
    
    public func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        let _ = textureInputSemaphore.wait(timeout:DispatchTime.distantFuture)
        defer {//函数返回时执行{}中语句
            textureInputSemaphore.signal()
        }
        
        inputTextures[fromSourceIndex] = texture
        
        if (UInt(inputTextures.count) >= maximumInputs) || activatePassthroughOnNextFrame {
            let outputWidth:Int
            let outputHeight:Int
            
            let firstInputTexture = inputTextures[0]!
            if firstInputTexture.orientation.rotationNeeded(for:.portrait).flipsDimensions() {
                outputWidth = firstInputTexture.texture.height
                outputHeight = firstInputTexture.texture.width
            } else {
                outputWidth = firstInputTexture.texture.width
                outputHeight = firstInputTexture.texture.height
            }

            if uniformSettings.usesAspectRatio {
                let outputRotation = firstInputTexture.orientation.rotationNeeded(for:.portrait)
                uniformSettings["aspectRatio"] = firstInputTexture.aspectRatio(for: outputRotation)
            }
            
            /*
             Create a new command buffer for each render pass to the current drawable.
             command buffer存放每次渲染的指令,即包含了每次渲染所需要的信息，直到指令被提交到GPU执行
             If the command queue has a maximum number of command buffers and the app
             already has that many buffers waiting, this method blocks until a buffer
             becomes available.
             
             command buffer是“一次性对象”，不支持重用。一旦command buffer被提交执行，唯一能做的是等待command buffer被调度或完成。
             
             */
            guard let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else {return}

            let outputTexture = Texture(device:sharedMetalRenderingDevice.device, orientation: .portrait, width: outputWidth, height: outputHeight, timingStyle: firstInputTexture.timingStyle)
            
            guard (!activatePassthroughOnNextFrame) else { // Use this to allow a bootstrap of cyclical processing, like with a low pass filter
                activatePassthroughOnNextFrame = false
                // TODO: Render rotated passthrough image here
                
                removeTransientInputs()
                textureInputSemaphore.signal()
                updateTargetsWithTexture(outputTexture)
                let _ = textureInputSemaphore.wait(timeout:DispatchTime.distantFuture)

                return
            }
            
            if let alternateRenderingFunction = metalPerformanceShaderPathway, useMetalPerformanceShaders
            {
                var rotatedInputTextures: [UInt:Texture]
                if (firstInputTexture.orientation.rotationNeeded(for:.portrait) != .noRotation)
                {
                    let rotationOutputTexture = Texture(device:sharedMetalRenderingDevice.device, orientation: .portrait, width: outputWidth, height: outputHeight)
                    guard let rotationCommandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else {
                        return
                    }
                    /*
                     renderQuad 为extension MTLCommandBuffer{} 中扩展的方法
                     */
                    rotationCommandBuffer.renderQuad(pipelineState: sharedMetalRenderingDevice.passthroughRenderState,
                                                     uniformSettings: uniformSettings,
                                                     inputTextures: inputTextures,
                                                     useNormalizedTextureCoordinates: useNormalizedTextureCoordinates,
                                                     outputTexture: rotationOutputTexture)
                    rotationCommandBuffer.commit()
                    rotatedInputTextures = inputTextures
                    rotatedInputTextures[0] = rotationOutputTexture
                } else {
                    rotatedInputTextures = inputTextures
                }
                alternateRenderingFunction(commandBuffer, rotatedInputTextures, outputTexture)
            } else {
                internalRenderFunction(commandBuffer: commandBuffer, outputTexture: outputTexture)
            }
            /*
             After you call the commit() method, the MTLDevice schedules and executes the commands in the command buffer.
             If you haven’t already enqueued the command buffer with a call to enqueue(), calling this function also
             enqueues the command buffer. The GPU executes the command buffer after any command buffers enqueued before
             it on the same command queue.
             也就是将command 提交到command queue 中，GPU会从这个queue中获取并执行command进行渲染
             */
            commandBuffer.commit()
            
            removeTransientInputs()
            textureInputSemaphore.signal()
            /*
             渲染结束，获取下个滤镜进行渲染，或者输出
             以当前的结果作为下一个渲染的输入
             */
            updateTargetsWithTexture(outputTexture)
            let _ = textureInputSemaphore.wait(timeout:DispatchTime.distantFuture)
        }
    }
    
    func removeTransientInputs() {
        for index in 0..<self.maximumInputs {
            if let texture = inputTextures[index], texture.timingStyle.isTransient() {
                inputTextures[index] = nil
            }
        }
    }
    
    func internalRenderFunction(commandBuffer: MTLCommandBuffer, outputTexture: Texture) {
        commandBuffer.renderQuad(pipelineState: renderPipelineState,//在初始化时已经准备好了着色器函数
                                 uniformSettings: uniformSettings,
                                 inputTextures: inputTextures,
                                 useNormalizedTextureCoordinates: useNormalizedTextureCoordinates,
                                 outputTexture: outputTexture)
    }
}
