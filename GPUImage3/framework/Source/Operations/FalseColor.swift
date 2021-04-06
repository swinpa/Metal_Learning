/**
 使用图像的亮度在两个用户指定的颜色之间混合。
 firstColor:Color 代表暗区的颜色。
 secondColor:Color 代表亮区的颜色。
 */
public class FalseColor: BasicOperation {
    public var firstColor:Color = Color(red:0.0, green:0.0, blue:0.5, alpha:1.0) { didSet { uniformSettings["firstColor"] = firstColor } }
    public var secondColor:Color = Color.red { didSet { uniformSettings["secondColor"] = secondColor } }
    
    public init() {
        super.init(fragmentFunctionName:"falseColorFragment", numberOfInputs:1)
        
        uniformSettings.colorUniformsUseAlpha = true
        ({firstColor = Color(red:0.0, green:0.0, blue:0.5, alpha:1.0)})()
        ({secondColor = Color.red})()
    }
}
