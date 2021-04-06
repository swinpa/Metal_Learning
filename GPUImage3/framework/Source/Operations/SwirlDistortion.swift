/**
 旋涡扭曲。
 radius:Float 扭曲的半径，默认0.5。
 angle:Float 扭曲量，默认1.0。
 center:Position 扭曲的中心，默认center。
 */
public class SwirlDistortion: BasicOperation {
    public var radius:Float = 0.5 { didSet { uniformSettings["radius"] = radius } }
    public var angle:Float = 1.0 { didSet { uniformSettings["angle"] = angle } }
    public var center:Position = Position.center { didSet { uniformSettings["center"] = center } }
    
    public init() {
        super.init(fragmentFunctionName:"swirlFragment", numberOfInputs:1)
        
        ({radius = 0.5})()
        ({angle = 1.0})()
        ({center = Position.center})()
    }
}
