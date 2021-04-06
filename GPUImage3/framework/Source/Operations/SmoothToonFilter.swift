/**
 类似ToonFilter，但有高斯模糊效果，以平滑噪点。
 blurRadiusInPixels:Float 高斯模糊半径，默认2.0。
 threshold:Float 边缘检测的灵敏度，低值更敏感，取值[0.0, 1.0]，默认0.2。
 quantizationLevels:Float 最终图像中颜色级别的数量，默认10.0。
 */
public class SmoothToonFilter: OperationGroup {
    public var blurRadiusInPixels: Float = 2.0 { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    public var threshold: Float = 0.2 { didSet { toonFilter.threshold = threshold } }
    public var quantizationLevels: Float = 10.0 { didSet { toonFilter.quantizationLevels = quantizationLevels } }
    
    let gaussianBlur = GaussianBlur()
    let toonFilter = ToonFilter()
    
    public override init() {
        super.init()
        
        ({blurRadiusInPixels = 2.0})()
        ({threshold = 0.2})()
        ({quantizationLevels = 10.0})()
        
        self.configureGroup{input, output in
            input --> self.gaussianBlur --> self.toonFilter --> output
        }
    }
}
