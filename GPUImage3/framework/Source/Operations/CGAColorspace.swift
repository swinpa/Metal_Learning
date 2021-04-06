/**
 模拟CGA显示器的颜色空间。
 */
public class CGAColorspaceFilter: BasicOperation {
    public init() {
        super.init(fragmentFunctionName:"CGAColorspaceFragment", numberOfInputs:1)
    }
}
