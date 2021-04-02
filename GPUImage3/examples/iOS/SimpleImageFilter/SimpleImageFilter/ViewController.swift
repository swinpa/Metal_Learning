import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture:PictureInput!
    var filter:SaturationAdjustment!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
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
        filter = SaturationAdjustment()
        /*
         Pipeline.swift 中定义了 --> 操作符，实现的是将 --> 操作符右边的参数添加到 --> 操作符左边参数的targets 中，并且返回-->操作符右边参数
         滤镜中也有targets这字段，故也可以通过--> 操作符添加下一个滤镜，或者输出
         */
        picture --> filter --> renderView
        /*
         picture.processImage()最终会遍历他的targets(在这里装的是filter = SaturationAdjustment()这个滤镜)
         然后执行滤镜的 newTextureAvailable(_ texture:Texture, fromSourceIndex:UInt)方法进行渲染
         */
        picture.processImage()
    }
}

