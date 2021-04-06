/**
 调整图像的饱和度
 saturation:Float 饱和度，取值[0.0, 2.0]，默认1.0。
 */
public class SaturationAdjustment: BasicOperation {
    public var saturation:Float = 1.0 { didSet { uniformSettings["saturation"] = saturation } }
    
    public init() {
        //初始化时，根据fragmentFunctionName 生成着色器
        super.init(fragmentFunctionName:"saturationFragment", numberOfInputs:1)
        
        ({saturation = 1.0})()
    }
}
