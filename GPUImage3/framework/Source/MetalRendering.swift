import Foundation
import Metal

// OpenGL uses a bottom-left origin while Metal uses a top-left origin.
public let standardImageVertices:[Float] = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0]

extension MTLCommandBuffer {
    func clear(with color: Color, outputTexture: Texture) {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = outputTexture.texture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(Double(color.redComponent), Double(color.greenComponent), Double(color.blueComponent), Double(color.alphaComponent))
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        
        print("Clear color: \(renderPass.colorAttachments[0].clearColor)")
        
        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("Could not create render encoder")
        }
//        renderEncoder.setRenderPipelineState(sharedMetalRenderingDevice.passthroughRenderState)

//        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 0)

        renderEncoder.endEncoding()
    }
    /// 提交渲染指令
    /// - Parameters:
    ///   - pipelineState: 渲染管线状态
    ///   - uniformSettings: 控制核心
    ///   - inputTextures: 输入的纹理们
    ///   - useNormalizedTextureCoordinates: 使用归一化纹理坐标
    ///   - imageVertices: 图片坐标点（实际上是显示区域）
    ///   - outputTexture: 输出纹理
    ///   - outputOrientation: 输出方向
    func renderQuad(pipelineState:MTLRenderPipelineState,
                    uniformSettings:ShaderUniformSettings? = nil,
                    inputTextures:[UInt:Texture],
                    useNormalizedTextureCoordinates:Bool = true,
                    imageVertices:[Float] = standardImageVertices,
                    outputTexture:Texture,
                    outputOrientation:ImageOrientation = .portrait) {
        //申请缓存
        let vertexBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: imageVertices,
                                                                        length: imageVertices.count * MemoryLayout<Float>.size,
                                                                        options: [])!
        vertexBuffer.label = "Vertices"
        
        /* Obtain a renderPassDescriptor generated from the view's drawable textures
         获取从视图的可绘制纹理生成的renderPassDescriptor
         MTLRenderPassDescriptor 承载渲染目标
         
         官方文档另外还解释如下：一个MTLRenderPassDescriptor对象包含一组attachments，作为rendering pass产生的像素的目的地。
         MTLRenderPassDescriptor还可以用来设置目标缓冲来保存rendering pass产生的可见性信息（光照可见性等用法，也就是自定义GBuffer的用法）。
         
         /*
          不看rendering pass，单看pass，你可以在很多算法的paper中看到类似概念。我的理解就是，一个pass，
          就是对一组数据的统一处理过程。比如，图像处理中高斯模糊一张图片，一般会有一个horizontal pass，
          一个vertical pass，就是说，我先水平处理一次所有像素，然后再垂直处理一遍。
          这里面，就是对图像中像素的一次统一处理，就是一个pass。放到shadow map里面，第一个pass就是要处理一次所有产生阴影的物体，
          是第一个shadow map的pass; 用第一个shadow map pass产生的贴图去绘制场景中产生的阴影，是第二个pass。
          这里面，对于场景的每一个模型用给定的渲染状态来进行一次drawcall处理，就是一个pass。
          因此，一个Tech，就是一个算法实现，一个pass，就是对一组数据的统一处理步骤。当然，个人理解而已。

          因此MTLRenderPassDescriptor 是不是次面上翻译成“渲染过程描述”
          
          */
         
        */
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = outputTexture.texture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        
        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("Could not create render encoder")
        }
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        for textureIndex in 0..<inputTextures.count {
            let currentTexture = inputTextures[UInt(textureIndex)]!
            
            let inputTextureCoordinates = currentTexture.textureCoordinates(for:outputOrientation, normalized:useNormalizedTextureCoordinates)
            let textureBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: inputTextureCoordinates,
                                                                             length: inputTextureCoordinates.count * MemoryLayout<Float>.size,
                                                                             options: [])!
            textureBuffer.label = "Texture Coordinates"

            renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1 + textureIndex)
            renderEncoder.setFragmentTexture(currentTexture.texture, index: textureIndex)
        }
        uniformSettings?.restoreShaderSettings(renderEncoder: renderEncoder)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}

func generateRenderPipelineState(device:MetalRenderingDevice, vertexFunctionName:String, fragmentFunctionName:String, operationName:String) -> (MTLRenderPipelineState, [String:(Int, MTLDataType)]) {
    guard let vertexFunction = device.shaderLibrary.makeFunction(name: vertexFunctionName) else {
        fatalError("\(operationName): could not compile vertex function \(vertexFunctionName)")
    }
    
    guard let fragmentFunction = device.shaderLibrary.makeFunction(name: fragmentFunctionName) else {
        fatalError("\(operationName): could not compile fragment function \(fragmentFunctionName)")
    }
    
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    descriptor.rasterSampleCount = 1
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    
    do {
        var reflection:MTLAutoreleasedRenderPipelineReflection?
        let pipelineState = try device.device.makeRenderPipelineState(descriptor: descriptor, options: [.bufferTypeInfo, .argumentInfo], reflection: &reflection)

        var uniformLookupTable:[String:(Int, MTLDataType)] = [:]
        if let fragmentArguments = reflection?.fragmentArguments {
            for fragmentArgument in fragmentArguments where fragmentArgument.type == .buffer {
                if
                  (fragmentArgument.bufferDataType == .struct),
                  let members = fragmentArgument.bufferStructType?.members.enumerated() {
                    for (index, uniform) in members {
                        uniformLookupTable[uniform.name] = (index, uniform.dataType)
                    }
                }
            }
        }
        
        return (pipelineState, uniformLookupTable)
    } catch {
        fatalError("Could not create render pipeline state for vertex:\(vertexFunctionName), fragment:\(fragmentFunctionName), error:\(error)")
    }
}
