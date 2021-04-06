/** A photo filter based on Photoshop action by Miss Etikate:
 http://miss-etikate.deviantart.com/art/Photoshop-Action-15-120151961
 Miss Etikate制作的基于Photoshop操作的滤，继承自LookupFilter
 */

public class MissEtikateFilter: LookupFilter {
    public override init() {
        super.init()
        
        ({lookupImage = PictureInput(imageName:"lookup_miss_etikate.png")})()
    }
}
