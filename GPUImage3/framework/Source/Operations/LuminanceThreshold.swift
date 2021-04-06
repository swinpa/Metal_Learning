/**
 亮度阈值。亮度高于阈值的像素将显示为白色，低于的像素将显示为黑色。
 threshold:Float 亮度阈值，取值[0.0, 1.0]，默认0.5。
 */
public class LuminanceThreshold: BasicOperation {
    public var threshold:Float = 0.5 { didSet { uniformSettings["threshold"] = threshold } }
    
    public init() {
        super.init(fragmentFunctionName: "thresholdFragment", numberOfInputs:1)
        
        ({threshold = 0.5})()
    }
}
