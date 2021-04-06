/**
 将图像转换为素描样式，这是图像处理中SobelEdgeDetection的颜色反转效果。
 edgeStrength:Float 调整动态范围，值越高边缘越强，默认1.0。
 */
public class SketchFilter: TextureSamplingOperation {
    public var edgeStrength:Float = 1.0 { didSet { uniformSettings["edgeStrength"] = edgeStrength } }
    
    public init() {
        super.init(fragmentFunctionName:"sketchFragment", numberOfInputs:1)
        
        ({edgeStrength = 1.0})()
    }
}
