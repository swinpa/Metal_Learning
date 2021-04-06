/**
 将图像在网格内分割为彩色点。
 dotScaling:Float 网格内点的大小，取值[0.0, 1.0]，默认0.9。
 fractionalWidthOfAPixel:Float 网格的大小，取值[0.0, 1.0]，默认0.01。
 */
public class PolkaDot: BasicOperation {
    public var dotScaling:Float = 0.90 { didSet { uniformSettings["dotScaling"] = dotScaling } }
    public var fractionalWidthOfAPixel:Float = 0.01{
        didSet {
            uniformSettings["fractionalWidthOfPixel"] = max(fractionalWidthOfAPixel, 0.01)
        }
    }
    
    public init() {
        super.init(fragmentFunctionName:"polkaDotFragment", numberOfInputs:1)
        
        ({fractionalWidthOfAPixel = 0.01})()
        ({dotScaling = 0.90})()
    }
}
