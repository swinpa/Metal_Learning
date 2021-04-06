/**
 自适应阈值。确定像素周围的局部亮度，然后如果像素低于该局部亮度则将像素变为黑色，如果高于则为白色。这可以用于在不同的照明条件下挑选文本。
 blurRadiusInPixels:Float 背景平均模糊半径（以像素为单位）的系数，默认4.0。
 */
public class AdaptiveThreshold: OperationGroup {
    public var blurRadiusInPixels: Float { didSet { boxBlur.blurRadiusInPixels = blurRadiusInPixels } }
    
    let luminance = Luminance()
    let boxBlur = BoxBlur()
    let adaptiveThreshold = BasicOperation(fragmentFunctionName:"adaptiveThresholdFragment", numberOfInputs:2)
    
    public override init() {
        blurRadiusInPixels = 4.0
        super.init()
        
        self.configureGroup{input, output in
            input --> self.luminance --> self.boxBlur --> self.adaptiveThreshold --> output
                      self.luminance --> self.adaptiveThreshold
        }
    }
}
