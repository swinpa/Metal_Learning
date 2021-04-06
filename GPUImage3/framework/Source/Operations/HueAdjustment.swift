/**
 调整色调。
 hue:Float 色调，以度为单位。默认90。
 */
public class HueAdjustment: BasicOperation {
    public var hue:Float = 90.0 { didSet { uniformSettings["hue"] = hue } }
    
    public init() {
        super.init(fragmentFunctionName:"hueFragment", numberOfInputs:1)
        
        ({hue = 90.0})()
    }
}
