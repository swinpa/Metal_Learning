/** A photo filter based on Photoshop action by Amatorka
 http://amatorka.deviantart.com/art/Amatorka-Action-2-121069631
 
 基于Photoshop操作的Amatorka图像滤镜，继承自LookupFilter。

 */

public class AmatorkaFilter: LookupFilter {
    public override init() {
        super.init()
        
        ({lookupImage = PictureInput(imageName:"lookup_amatorka.png")})()
        ({intensity = 1.0})()
    }
}
