/**
 用于添加或去除雾度（类似于UV过滤器）。
 distance:Float 应用的颜色的强度，取值[-0.3, 0.3]，默认0.0。
 slope:Float 颜色变化量，取值[-0.3, 0.3]，默认0.0。
 */
public class Haze: BasicOperation {
    public var distance:Float = 0.2 { didSet { uniformSettings["hazeDistance"] = distance } }
    public var slope:Float = 0.0 { didSet { uniformSettings["slope"] = slope } }
    
    public init() {
        super.init(fragmentFunctionName:"hazeFragment", numberOfInputs:1)
        
        ({distance = 0.2})()
        ({slope = 0.0})()
    }
}
