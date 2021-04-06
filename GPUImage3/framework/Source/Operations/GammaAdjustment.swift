/**
 调整图像的灰度
 gamma:Float 要调整的灰度，取值[0.0, 3.0]，默认1.0。
 */
public class GammaAdjustment: BasicOperation {
    public var gamma:Float = 1.0 { didSet { uniformSettings["gamma"] = gamma } }
    
    public init() {
        super.init(fragmentFunctionName:"gammaFragment", numberOfInputs:1)
        
        ({gamma = 1.0})()
    }
}
