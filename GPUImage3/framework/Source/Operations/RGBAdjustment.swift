/**
 调整图像的RGB通道。
 red:Float
 blue:Float
 green:Float
 取值[0.0, ∞)，默认为1.0。
 */
public class RGBAdjustment: BasicOperation {
    public var red:Float = 1.0 { didSet { uniformSettings["redAdjustment"] = red } }
    public var blue:Float = 1.0 { didSet { uniformSettings["blueAdjustment"] = blue } }
    public var green:Float = 1.0 { didSet { uniformSettings["greenAdjustment"] = green } }
    
    public init() {
        super.init(fragmentFunctionName:"rgbAdjustmentFragment", numberOfInputs:1)
        
        ({red = 1.0})()
        ({blue = 1.0})()
        ({green = 1.0})()
    }
}
