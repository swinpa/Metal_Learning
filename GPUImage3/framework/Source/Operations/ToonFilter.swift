/**
 使用SobelEdgeDetection在对象周围进行黑色描边，然后它量化图像中存在的颜色，并给图像一个卡通的效果。
 threshold:Float 边缘检测的灵敏度，低值更敏感，取值[0.0, 1.0]，默认0.2。
 quantizationLevels:Float 最终图像中颜色级别的数量，默认10.0。
 */
public class ToonFilter: TextureSamplingOperation {
    public var threshold:Float = 0.2 { didSet { uniformSettings["threshold"] = threshold } }
    public var quantizationLevels:Float = 10.0 { didSet { uniformSettings["quantizationLevels"] = quantizationLevels } }
    
    public init() {
        super.init(fragmentFunctionName:"toonFragment", numberOfInputs:1)
        
        ({threshold = 0.2})()
        ({quantizationLevels = 10.0})()
    }
}
