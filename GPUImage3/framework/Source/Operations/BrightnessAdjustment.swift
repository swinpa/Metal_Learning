/// 调整图像的亮度。brightness:Float 调整后的亮度，取值[-1.0, 1.0]，默认为0.0。

public class BrightnessAdjustment: BasicOperation {
    public var brightness:Float = 0.0 { didSet { uniformSettings["brightness"] = brightness } }
    
    public init() {
        super.init(fragmentFunctionName:"brightnessFragment", numberOfInputs:1)
        
        ({brightness = 0.0})()
    }
}
