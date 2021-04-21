#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct
{
    float saturation;
} SaturationUniform;

/*
 
 原理参考文章：https://xiaozhuanlan.com/topic/3654810792
 
 饱和度是指图像颜色的浓度。

 饱和度越高，颜色越饱满，即所谓的青翠欲滴的感觉。
 饱和度越低，颜色就会显得越陈旧、惨淡。
 饱和度为0时，图像就为灰度图像。
 在算法实现上，饱和度《表示》《色相中》《灰色分量》所占的比例，它使用从0%（灰色）至100%（完全饱和）的百分比来度量。所以，为了控制图像的饱和度，我们可以创建一个灰度基准图像。

 而灰度图，存储的其实是颜色的亮度值（Luminance）信息（这里的亮度值不是亮度滤镜中的亮度的意思）。
 
 Luminance 亮度，指的是投射在固定方向和面积上的发光强度，发光强度是一个可测量的属性。

 所谓可测量，是指在 sRGB 规范中，Luminance(亮度) 被定义为 RGB 的线形组合，sRGB 中基于亮度值的权值向量为：
 constant half3 luminanceWeighting = half3(0.2125, 0.7154, 0.0721);
 
 所以，在 Fragment Function 中，某个片段的像素值 color，对应的亮度为：
 
 half luminance = dot(color.rgb, luminanceWeighting);
 
 
 PS：

 dot()为内置函数，向量点乘。
 T s dot(T x, T y) ：Return the dot product of x and y。
 i.e., x[0] * y[0] + x[1] * y[1] + …

 内置函数，向量点乘。
 
 */
fragment half4 saturationFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant SaturationUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    half luminance = dot(color.rgb, luminanceWeighting);

    return half4(mix(half3(luminance), color.rgb, half(uniform.saturation)), color.a);
}
