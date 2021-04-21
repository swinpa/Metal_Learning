#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct
{
    float intensity;
} IntensityUniform;
/*
 原理文章：https://www.coderzhou.com/2019/02/21/Metal%E5%AD%A6%E4%B9%A0(%E4%B8%89)%EF%BC%9A%E5%AE%9E%E6%88%98%E4%B9%8BLUT%E6%BB%A4%E9%95%9C%E5%8F%8A%E9%A5%B1%E5%92%8C%E5%BA%A6%E6%A8%A1%E7%B3%8A%E5%BA%A6%E8%B0%83%E8%8A%82/
 文章中的
    “1、用蓝色值R计算正方形的位置，假如一个像素点原来rgb是(0.1, 0.2, 0.4)，那么B = 0.4，则(0.4 63 = 25.6)/8 = 3，（25 - 3 8）= 1，即第3行第1列的那个大正方形，quad1.y = 3，quad1.x = 1.”
 (0.4 63 = 25.6)/8 = 3 应该是 (0.4 x 63)/8 = 3 ,
 (25 - 3 8）= 1        应该是 25 - (3 x 8) = 1 ,
 其中 04 x 8 = 25.2 表示蓝色分量大概在第25个方格中(当然顺序是从左往右，从上往下)
 根据每行8个方格，所以(0.4 x 63)/8 = 3就表示蓝色分量大概在第3行的方格中
 根据每行8个方格，所以25 - (3 x 8) = 1就表示蓝色分量大概在第1列的方格中(其实这里跟用求余方法时一样的 25 % 8 = 1)
 
 
 
 
 https://xiaozhuanlan.com/topic/3654810792
 
 对lookup表（一张色值卡）来说，每个大方格中的所有小方格的B分量是一样的
 
 整体对每个小方块而言，从左上往右下 B 从 0 到 1 ，是 z 字型的顺序
 单独对每个小方块而言，从左到右 R 从 0 到 1，代表 x
 单独对每个小方块而言，从上到下 G 从 0 到 1，代表 y
 
 */

/*
 fragment -- 片段着色器
 片段着色器的主要作用是计算一个像素的最终颜色
 在片段着色器之前的阶段，渲染管线都只是在和顶点，图元打交道。片段着色器可以根据顶点着色器输出的顶点纹理坐标对纹理
 进行采样(从纹理坐标获取纹理颜色叫做采样(Sampling))，以计算该片段的颜色值。从而调整成各种各样不同的效果图，
 这也是所有OpenGL或Metal高级效果产生的地方
 
 片段着色器的返回值是一个四维向量，即是这个片元的颜色 RGBA 值
 */
fragment half4 lookupFragment(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant IntensityUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    //正常的纹理颜色
    half4 base = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    /*
     rgb是(0.1, 0.2, 0.4)
     */
    half blueColor = base.b * 63.0h;// 蓝色部分[0, 63] 共64种，0.4 * 63 = 25.2
    
    
    /*
     rgb是(0.1, 0.2, 0.4)
     
     round  如果参数是小数  则求本身的四舍五入.
     ceil   如果参数是小数  则求最小的整数但不小于本身.(向上取舍)
     floor  如果参数是小数  则求最大的整数但不大于本身.(向下取舍)
     round(3.4)  --- 3   ceil(3.4) --- 4   floor(3.4) --- 3
     round(3.5)  --- 4   ceil(3.5) --- 4    floor(3.5) --- 3
     */
    
    /*
     第一步：用蓝色值R计算正方形的位置（计算得出使用lookup表中的哪个方格）
     
     
     [
        [00][01][02][03][04][05][06][07]
        [08][09][10][11][12][13][14][15]
        [16][17][18][19][20][21][22][23]
        [24][25][26][27][28][29][30][31]
        [32][33][34][35][36][37][38][39]
        [40][41][42][43][44][45][46][47]
        [48][49][50][51][52][53][54][55]
        [56][57][58][59][60][61][62][63]
     ]
     
     
     */
    
    //这里计算在lookup表中的第几行方格？(取整)
    half2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0h);
    //这里计算在lookup表中的第几列方格？(这里相当于求余%)
    quad1.x = floor(blueColor) - (quad1.y * 8.0h);
    
    half2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0h);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0h);
    
    
    /*
     第二步：根据红色值和绿色值计算对应位置在整个纹理的坐标。（也就是计算得出在小方格内的坐标）
     */
    
    float2 texPos1;
    //               quad1.x/8
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * base.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * base.g);
    
    float2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * base.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * base.g);
    
    constexpr sampler quadSampler3;
    /*
     从lookuptable 的纹理中，根据位置（texPos）获取对应的像素值
     这样的话我们就能从颜色查找表中得到了对应的转换后的颜色。
     */
    half4 newColor1 = inputTexture2.sample(quadSampler3, texPos1);
    constexpr sampler quadSampler4;
    half4 newColor2 = inputTexture2.sample(quadSampler4, texPos2);
    
    half4 newColor = mix(newColor1, newColor2, fract(blueColor));
    return half4(mix(base, half4(newColor.rgb, base.w), half(uniform.intensity)));
}
