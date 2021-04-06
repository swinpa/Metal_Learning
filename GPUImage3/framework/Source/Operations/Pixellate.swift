/**
 像素化（马赛克）。
 fractionalWidthOfAPixel:Float 像素块的大小，取值[0.0, 1.0]，默认0.01。
 */
public class Pixellate: BasicOperation {
    public var fractionalWidthOfAPixel:Float = 0.01 {
        didSet {
            uniformSettings["fractionalWidthOfPixel"] = max(fractionalWidthOfAPixel, 0.01)
        }
    }
    
    public init() {
        super.init(fragmentFunctionName:"pixellateFragment", numberOfInputs:1)
        
        ({fractionalWidthOfAPixel = 0.01})()
    }
}
