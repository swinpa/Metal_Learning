// Issues with Size not working with the compiler
/**
 基于极坐标的像素化。
 pixelSize:Size 像素大小，默认(0.05, 0.05)。
 center:Position 像素的中心，默认center。
 */
public class PolarPixellate: BasicOperation {
    public var pixelSize:Size = Size(width:0.05, height:0.05) { didSet { uniformSettings["pixelSize"] = pixelSize } }
    public var center:Position = Position.center { didSet { uniformSettings["center"] = center } }
    
    public init() {
        super.init(fragmentFunctionName:"polarPixellateFragment", numberOfInputs:1)
        
        ({pixelSize = Size(width:0.05, height:0.05)})()
        ({center = Position.center})()
    }
}
