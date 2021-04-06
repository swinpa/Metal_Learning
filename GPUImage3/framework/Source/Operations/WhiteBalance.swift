/**
 调整白平衡
 temperature:Float 以ºK为单位调整图像的温度，取值[4000.0, 7000.0]。4000是非常冷，7000是非常温暖。默认5000。4000和5000之间的比例与5000和7000之间的比例几乎相等。
 tint:Float 取值[-200.0, 200.0]，值为-200非常绿色，200非常粉红色。默认值为0。
 */
/*
public class WhiteBalance: BasicOperation {
    public var temperature:Float = 5000.0 { didSet { uniformSettings["temperature"] = temperature < 5000.0 ? 0.0004 * (temperature - 5000.0) : 0.00006 * (temperature - 5000.0) } }
    public var tint:Float = 0.0 { didSet { uniformSettings["tint"] = tint / 100.0 } }
    
    public init() {
        super.init(fragmentFunctionName:"whiteBalanceFragmentShader", numberOfInputs:1)
        
        uniformSettings.appendUniform(5000.0)
        uniformSettings.appendUniform(0.0)
    }
}
 */
