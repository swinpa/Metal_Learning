/**
 使用RGB查找并重新映射图像中的颜色。
 lookupImage:PictureInput 目标图像
 intensity:Float 效果的强度，取值[0.0, 1.0]，默认0.0。
 */
public class LookupFilter: BasicOperation {
    public var intensity:Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
    public var lookupImage:PictureInput? { // TODO: Check for retain cycles in all cases here
        didSet {
            lookupImage?.addTarget(self, atTargetIndex:1)
            lookupImage?.processImage()
        }
    }
    
    public init() {
        super.init(fragmentFunctionName:"lookupFragment", numberOfInputs:2)
        
        ({intensity = 1.0})()
    }
}
