/**
 KuwaharaFilter的修改版，优化超过三个像素半径计算。
 */
public class KuwaharaRadius3Filter: BasicOperation {
    public init() {
        super.init(fragmentFunctionName:"kuwaharaRadius3Fragment", numberOfInputs:1)
    }
}
