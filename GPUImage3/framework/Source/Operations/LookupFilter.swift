/**
 使用RGB查找并重新映射图像中的颜色。
 lookupImage:PictureInput 目标图像
 intensity:Float 效果的强度，取值[0.0, 1.0]，默认0.0。
 
  原理文章：https://www.coderzhou.com/2019/02/21/Metal%E5%AD%A6%E4%B9%A0(%E4%B8%89)%EF%BC%9A%E5%AE%9E%E6%88%98%E4%B9%8BLUT%E6%BB%A4%E9%95%9C%E5%8F%8A%E9%A5%B1%E5%92%8C%E5%BA%A6%E6%A8%A1%E7%B3%8A%E5%BA%A6%E8%B0%83%E8%8A%82/
 */
public class LookupFilter: BasicOperation {
    public var intensity:Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
    public var lookupImage:PictureInput? { // TODO: Check for retain cycles in all cases here
        didSet {
            lookupImage?.addTarget(self, atTargetIndex:1)
            //先将lookup 图
            lookupImage?.processImage()
        }
    }
    
    public init() {
        super.init(fragmentFunctionName:"lookupFragment", numberOfInputs:2)
        
        ({intensity = 1.0})()
    }
}
