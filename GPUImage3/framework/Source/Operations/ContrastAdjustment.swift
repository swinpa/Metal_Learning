/**
 调整图像的对比度。
 contrast:Float 调整的对比度，取值[0.0, 4.0]，默认1.0。
 */
public class ContrastAdjustment: BasicOperation {
    public var contrast:Float = 1.0 { didSet { uniformSettings["contrast"] = contrast } }
    
    public init() {
        super.init(fragmentFunctionName:"contrastFragment", numberOfInputs:1)
        
        ({contrast = 1.0})()
    }
}
