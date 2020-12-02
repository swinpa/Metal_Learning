/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands.
#include "AAPLShaderTypes.h"

/*
 渲染过程：
 读取顶点数据——执行顶点着色器——组装图元——光栅化图元——执行片元着色器——写入帧缓冲区——显示到屏幕上。
 */

/*
 
 
 
 primitives -> vertex function -> Rasterization -> Fragment function -> xxx
 
 
 Rasterization：
     在光栅化阶段，基本图元被转换为供片段着色器使用的片段。简单来说，就是将数据转化成可见像素的过程。在片段着色器运行之前会执行裁切(Clipping)。裁切会丢弃超出你的视图以外的所有像素，用来提升执行效率。在Metal中，这一步是用户控制不了的，由系统自动处理
     
 Fragment function
     片段着色器的主要作用是计算一个像素的最终颜色
     在片段着色器之前的阶段，渲染管线都只是在和顶点，图元打交道。片段着色器可以根据顶点着色器输出的顶点纹理坐标对纹理进行采样(从纹理坐标获取纹理颜色叫做采样(Sampling))，以计算该片段的颜色值。从而调整成各种各样不同的效果图，这也是所有OpenGL或Metal高级效果产生的地方
     片段着色器的返回值是一个四维向量，即是这个片元的颜色 RGBA 值
     
 */

// Vertex shader outputs and fragment shader inputs
struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];

    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;
};

/*
 顶点着色器业务：
     矩阵变换位置
     计算光照公式生成逐顶点颜色
     生成/变换纹理坐标
 vertexShader的返回值会被作为片元着色器函数的输入。
 */
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant AAPLVertex *vertices [[buffer(AAPLVertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(AAPLVertexInputIndexViewportSize)]])
{
    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    // The positions are specified in pixel dimensions (i.e. a value of 100
    // is 100 pixels from the origin).
    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    // Get the viewport size and cast to float.
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);

    // Pass the input color directly to the rasterizer.
    out.color = vertices[vertexID].color;

    return out;
}

/*
 片元着色器
     片元着色器又叫片段着色器或像素着色器。
 
 片元着色器的输入：
     着色器程序 -- 描述片段上执行操作的片元着色器程序源代码/可执行文件。
     输入变量 -- 光栅化单元用插值为每个片段生成的顶点着色器输出
     统一变量(uniform) -- 顶点或片元着色器使用的不变数据
     采样器 -- 代表片元着色器使用纹理的特殊统一变量

 插值(Interpolation)：
     光栅器在三角形的三个顶点之间进行插值（或者通过另外一种技术一行一行的插值）并执行片元着色器遍历三角形的每一个像素。片元着色器会返回光栅器存在颜色缓存中用于显示的像素颜色值（在其他一些额外的检测之后，比如：深度测试depth test等）
 
 片元着色器业务：
     计算颜色
     获取纹理值
     往像素点中填充颜色值(纹理值/颜色值)

 它可以⽤于图⽚/视频/图形中每个像素的颜色填充(比如给视频添加滤镜,实际上就是将视频中每个图片的像素点颜色填充进行修改.)

 */
fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the interpolated color.
    return in.color;
}

