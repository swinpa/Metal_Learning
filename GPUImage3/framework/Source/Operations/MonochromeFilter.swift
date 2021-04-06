/**
 根据图像的像素亮度将其转换成单色。
 intensity:Float 转换的程度，取值[0.0, 1.0]，默认1.0。
 color:Color 效果的基础颜色。默认(0.6，0.45，0.3，1.0)。
 */
public class MonochromeFilter: BasicOperation {
    public var intensity:Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
    public var color:Color = Color(red:0.6, green:0.45, blue:0.3, alpha:1.0) { didSet { uniformSettings["filterColor"] = color } }
    
    public init() {
        super.init(fragmentFunctionName:"monochromeFragment", numberOfInputs:1)
        
        self.uniformSettings.colorUniformsUseAlpha = false
        ({intensity = 1.0})()
        ({color = Color(red:0.6, green:0.45, blue:0.3, alpha:1.0)})()
    }
}

