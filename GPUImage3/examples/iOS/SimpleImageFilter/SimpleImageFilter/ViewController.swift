import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture:PictureInput!
    var filter:LookupFilter!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //一些滤镜算法https://juejin.cn/post/6844903680244711431
        // Filtering image for saving
        let testImage = UIImage(named:"WID-small.jpg")!
        let toonFilter = ToonFilter()
        let filteredImage = testImage.filterWithOperation(toonFilter)
        
        let pngImage = UIImagePNGRepresentation(filteredImage)!
        do {
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            let fileURL = URL(string:"test.png", relativeTo:documentsDir)!
            try pngImage.write(to:fileURL, options:.atomic)
        } catch {
            print("Couldn't write to file with error: \(error)")
        }
        
        // Filtering image for display
        picture = PictureInput(image:UIImage(named:"WID-small.jpg")!)
        let lookuptable = PictureInput(image:UIImage(named:"lookupTable.jpg")!)
//        filter = SaturationAdjustment()
        filter = LookupFilter.init()
        filter.lookupImage = lookuptable
        
        /*
         Pipeline.swift 中定义了 --> 操作符，实现的是将 --> 操作符右边的参数添加到 --> 操作符左边参数的targets 中，并且返回-->操作符右边参数
         滤镜中也有targets这字段，故也可以通过--> 操作符添加下一个滤镜，或者输出
         */
        picture --> filter --> renderView
        /*
         picture.processImage()最终会遍历他的targets(在这里装的是filter = SaturationAdjustment()这个滤镜)
         然后执行滤镜的 newTextureAvailable(_ texture:Texture, fromSourceIndex:UInt)方法进行渲染
         
         picture中的target 是filter，filter 中的target是renderView
         所以当picture执行processImage 时会获取到filter并执行newTextureAvailable 进行渲染
         当filter 渲染完，他会拿取他的target（在这里是renderView）执行newTextureAvailable 进行渲染
         RenderView 会通过GPU 渲染到view上然后显示在屏幕上
         
         如果最后的是PictureOutput，则会经过GPU渲染后，根据渲染出来的纹理（像素数据）生成cgimage
         
         */
        picture.processImage()
    }
}

