/**
 KuwaharaFilter
 产生油画式的图像，但计算量非常大，适合用于静止图像。
 radius:Int 从中心像素向外测试的像素数。较高的值会创建更抽象的图像，但处理时间更长，默认3。
 */
public class KuwaharaFilter: BasicOperation {
    public var radius:Float = 3.0 { didSet { uniformSettings["radius"] = radius } }
    
    public init() {
        super.init(fragmentFunctionName:"kuwaharaFragment", numberOfInputs:1)
        
        ({radius = 3.0})()
    }
}
