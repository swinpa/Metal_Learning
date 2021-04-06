/**
 调整图像的曝光。
 exposure:Float 调整曝光，取值[-10.0, 10.0]，默认0.0.
 */
public class ExposureAdjustment: BasicOperation {
    public var exposure:Float = 0.0 { didSet { uniformSettings["exposure"] = exposure } }
    
    public init() {
        super.init(fragmentFunctionName:"exposureFragment", numberOfInputs:1)
        
        ({exposure = 0.0})()
    }
}
