/**
 使用矩阵转换颜色。
 intensity:Float 新颜色替换每个像素的原始颜色的程度。
 colorMatrix:Matrix4x4 一个4x4矩阵，用于变换图像中的每种颜色
 */
public class ColorMatrixFilter: BasicOperation {
    public var intensity:Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
    public var colorMatrix:Matrix4x4 = Matrix4x4.identity { didSet { uniformSettings["colorMatrix"] = colorMatrix } }
    
    public init() {
        
        super.init(fragmentFunctionName:"colorMatrixFragment", numberOfInputs:1)
        
        ({intensity = 1.0})()
        ({colorMatrix = Matrix4x4.identity})()
    }
}
