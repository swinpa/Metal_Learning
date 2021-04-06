/**
 将色彩动态范围减少到指定的等级，渲染出卡通式的简单阴影。
 colorLevels:Float 图像空间缩小到的颜色级别数。取值[1.0, 256.0]，默认1.0。
 */
public class Posterize: BasicOperation {
    public var colorLevels:Float = 10.0 { didSet { uniformSettings["colorLevels"] = colorLevels } }
    
    public init() {
        super.init(fragmentFunctionName: "posterizeFragment", numberOfInputs: 1)
        
        ({colorLevels = 10.0})()
    }
}
