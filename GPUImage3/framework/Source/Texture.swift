import Foundation
import Metal
#if os(iOS)
import UIKit
#endif

public enum TextureTimingStyle {
    case stillImage
    case videoFrame(timestamp:Timestamp)
    
    func isTransient() -> Bool {
        switch self {
        case .stillImage: return false
        case .videoFrame: return true
        }
    }
    
    var timestamp:Timestamp? {
        get {
            switch self {
            case .stillImage: return nil
            case let .videoFrame(timestamp): return timestamp
            }
        }
    }
}

public class Texture {
    public var timingStyle: TextureTimingStyle
    public var orientation: ImageOrientation
    
    public let texture: MTLTexture
    
    public init(orientation: ImageOrientation,
                texture: MTLTexture,
                timingStyle: TextureTimingStyle  = .stillImage)
    {
        self.orientation = orientation
        self.texture = texture
        self.timingStyle = timingStyle
    }
    
    public init(device:MTLDevice,
                orientation: ImageOrientation,
                pixelFormat: MTLPixelFormat = .bgra8Unorm,
                width: Int, height: Int,
                mipmapped:Bool = false,
                timingStyle: TextureTimingStyle  = .stillImage)
    {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        /*
         根据MTLTextureDescriptor(用来描述纹理texture的一些属性) 创建纹理texture
         When you create a texture, Metal copies property values from the descriptor into the new texture.
         You can reuse a MTLTextureDescriptor object, modifying its property values as needed,
         to create more MTLTexture objects, without affecting any textures you already created.
         也就是MTLTextureDescriptor 可以复用，修改而不会影响已经创建的texture，
         */
        guard let newTexture = sharedMetalRenderingDevice.device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Could not create texture of size: (\(width), \(height))")
        }

        self.orientation = orientation
        self.texture = newTexture
        self.timingStyle = timingStyle
    }
}

extension Texture {
    func textureCoordinates(for outputOrientation:ImageOrientation, normalized:Bool) -> [Float] {
        let inputRotation = self.orientation.rotationNeeded(for:outputOrientation)

        let xLimit:Float
        let yLimit:Float
        if normalized {
            xLimit = 1.0
            yLimit = 1.0
        } else {
            xLimit = Float(self.texture.width)
            yLimit = Float(self.texture.height)
        }
        
        switch inputRotation {
        case .noRotation: return [0.0, 0.0, xLimit, 0.0, 0.0, yLimit, xLimit, yLimit]
        case .rotateCounterclockwise: return [0.0, yLimit, 0.0, 0.0, xLimit, yLimit, xLimit, 0.0]
        case .rotateClockwise: return [xLimit, 0.0, xLimit, yLimit, 0.0, 0.0, 0.0, yLimit]
        case .rotate180: return [xLimit, yLimit, 0.0, yLimit, xLimit, 0.0, 0.0, 0.0]
        case .flipHorizontally: return [xLimit, 0.0, 0.0, 0.0, xLimit, yLimit, 0.0, yLimit]
        case .flipVertically: return [0.0, yLimit, xLimit, yLimit, 0.0, 0.0, xLimit, 0.0]
        case .rotateClockwiseAndFlipVertically: return [0.0, 0.0, 0.0, yLimit, xLimit, 0.0, xLimit, yLimit]
        case .rotateClockwiseAndFlipHorizontally: return [xLimit, yLimit, xLimit, 0.0, 0.0, yLimit, 0.0, 0.0]
        }
    }
    
    func aspectRatio(for rotation:Rotation) -> Float {
        // TODO: Figure out why my logic was failing on this
        return Float(self.texture.height) / Float(self.texture.width)
//        if rotation.flipsDimensions() {
//            return Float(self.texture.width) / Float(self.texture.height)
//        } else {
//            return Float(self.texture.height) / Float(self.texture.width)
//        }
    }

    
//    func croppedTextureCoordinates(offsetFromOrigin:Position, cropSize:Size) -> [Float] {
//        let minX = offsetFromOrigin.x
//        let minY = offsetFromOrigin.y
//        let maxX = offsetFromOrigin.x + cropSize.width
//        let maxY = offsetFromOrigin.y + cropSize.height
//
//        switch self {
//        case .noRotation: return [minX, minY, maxX, minY, minX, maxY, maxX, maxY]
//        case .rotateCounterclockwise: return [minX, maxY, minX, minY, maxX, maxY, maxX, minY]
//        case .rotateClockwise: return [maxX, minY, maxX, maxY, minX, minY, minX, maxY]
//        case .rotate180: return [maxX, maxY, minX, maxY, maxX, minY, minX, minY]
//        case .flipHorizontally: return [maxX, minY, minX, minY, maxX, maxY, minX, maxY]
//        case .flipVertically: return [minX, maxY, maxX, maxY, minX, minY, maxX, minY]
//        case .rotateClockwiseAndFlipVertically: return [minX, minY, minX, maxY, maxX, minY, maxX, maxY]
//        case .rotateClockwiseAndFlipHorizontally: return [maxX, maxY, maxX, minY, minX, maxY, minX, minY]
//        }
//    }
}

extension Texture {
    
    /*
     解释一下CIImage CGImage UIImage的区别：
     UIImage
     Apple describes a UIImage object as a high-level way to display image
     data. You can create images from files, from Quartz image objects, or
     from raw image data you receive. They are immutable and must specify
     an image’s properties at initialization time. This also means that
     these image objects are safe to use from any thread. Typically you can
     take NSData object containing a PNG or JPEG representation image and
     convert it to a UIImage. To create a new UIImage, for example:
     
     CGImage
     A CGImage can only representbitmaps. Operations in CoreGraphics, such
     as blend modes and masking require CGImageRefs. If you need to access
     and change the actual bitmap data, you can use CGImage. It can also be
     converted to NSBitmapImageReps. To create a new UIImage from a
     CGImage,
     
     
     CIImage
     A CIImage is a immutable object that represents an image. It isnot an
     image. It only has the image data associated with it. It has all the
     information necessary to produce an image. You typically use CIImage
     objects in conjunction with other Core Image classes such as CIFilter,
     CIContext, CIColor, and CIVector. You can create CIImage objects with
     data supplied from variety of sources such as Quartz 2D images, Core
     Videos image, etc. It is required to use the various GPU optimized
     Core Image filters. They can also be converted to NSBitmapImageReps.
     It can be based on the CPU or the GPU. To create a new CIImage,
     
     
     它们属于不同的框架：分别为UIKit，CoreGraphics，CoreImage。

     通常，您使用UIImage，除非您有使用其他框架方便的特定用例(例如使用CoreImage过滤器)。

     */
    
    func cgImage() -> CGImage {
        // Flip(翻转) and swizzle image
        guard let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else {
            fatalError("Could not create command buffer on image rendering.")
        }
        //获取输出纹理
        let outputTexture = Texture(device:sharedMetalRenderingDevice.device, orientation:self.orientation, width:self.texture.width, height:self.texture.height)
        /*
         对commandBuffer 进行编码，也就是通过编码告诉GPU处理的纹理是什么，处理完存储在哪里（输出纹理）,对纹理需要怎么处理（需要执行什么着色器）
         */
        commandBuffer.renderQuad(pipelineState:sharedMetalRenderingDevice.colorSwizzleRenderState,
                                 uniformSettings:nil,
                                 inputTextures:[0:self],
                                 useNormalizedTextureCoordinates:true,
                                 outputTexture:outputTexture)
        //提交到queue中开始进行渲染
        commandBuffer.commit()
        //等待渲染结束
        commandBuffer.waitUntilCompleted()
        
        // Grab texture bytes, generate CGImageRef from them
        let imageByteSize = texture.height * texture.width * 4
        let outputBytes = UnsafeMutablePointer<UInt8>.allocate(capacity:imageByteSize)
        /*
         Copies pixel data from a texture to memory.
         拿到渲染结束后的像素数据
         */
        outputTexture.texture.getBytes(outputBytes, bytesPerRow: MemoryLayout<UInt8>.size * texture.width * 4, bytesPerImage:0, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0, slice: 0)
        
        guard let dataProvider = CGDataProvider(dataInfo:nil, data:outputBytes, size:imageByteSize, releaseData:dataProviderReleaseCallback) else {fatalError("Could not create CGDataProvider")}
        let defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB()
        //根据像素数据生成cgimage
        return CGImage(width:texture.width,
                       height:texture.height,
                       bitsPerComponent:8,
                       bitsPerPixel:32,
                       bytesPerRow:4 * texture.width,
                       space:defaultRGBColorSpace,
                       bitmapInfo:CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider:dataProvider,
                       decode:nil,
                       shouldInterpolate:false,
                       intent:.defaultIntent)!
    }
}

func dataProviderReleaseCallback(_ context:UnsafeMutableRawPointer?, data:UnsafeRawPointer, size:Int) {
    data.deallocate()
}
