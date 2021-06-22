/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of a platform independent renderer class, which performs Metal setup and per frame rendering
*/

@import simd;
@import MetalKit;

#import "AAPLRenderer.h"

// Header shared between C code here, which executes Metal API commands, and .metal files, which
// uses these types as inputs to the shaders.
#import "AAPLShaderTypes.h"

// Main class performing the rendering
@implementation AAPLRenderer
{
    id<MTLDevice> _device;

    // The render pipeline generated from the vertex and fragment shaders in the .metal shader file.
    id<MTLRenderPipelineState> _pipelineState;

    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> _commandQueue;

    // The current size of the view, used as an input to the vertex shader.
    vector_uint2 _viewportSize;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        NSError *error;

        _device = mtkView.device;

        // Load all the shader files with a .metal file extension in the project.
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

        /* Configure a pipeline descriptor that is used to create a pipeline state.
         配置用于创建管道状态的管道描述符。
        */
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Simple Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;

        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];
                
        // Pipeline State creation could fail if the pipeline descriptor isn't set up properly.
        //  If the Metal API validation is enabled, you can find out more information about what
        //  went wrong.  (Metal API validation is enabled by default when a debug build is run
        //  from Xcode.)
        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);

        // Create the command queue
        _commandQueue = [_device newCommandQueue];
    }

    return self;
}

/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Save the size of the drawable to pass to the vertex shader.
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}


/*
 1，新建一个MTLCommandBuffer，
 2，使用MTLRenderCommandEncoder 将MTLCommandBuffer 需要做的事情Encoder到MTLCommandBuffer中
 3，设置 当MTLCommandBuffer 渲染的指令 结束后需要显示在哪个画布上
 4，以上步骤完成后需要通过 [commandBuffer commit] 将MTLCommandBuffer提交到MTLCommandQueue中，
 MTLCommandQueue 会有序的将其提交到GPU上执行
 */

/// Called whenever the view needs to render a frame.
- (void)drawInMTKView:(nonnull MTKView *)view
{
    static const AAPLVertex triangleVertices[] =
    {
        // 2D positions,    RGBA colors
        { {  250,  -250 }, { 1, 0, 0, 1 } },
        { { -250,  -250 }, { 0, 1, 0, 1 } },
        { {    0,   250 }, { 0, 0, 1, 1 } },
    };

    /*
     Create a new command buffer for each render pass to the current drawable.
     command buffer存放每次渲染的指令,即包含了每次渲染所需要的信息，直到指令被提交到GPU执行
     */
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    /*
     不看rendering pass，单看pass，你可以在很多算法的paper中看到类似概念。我的理解就是，一个pass，
     就是对一组数据的统一处理过程。比如，图像处理中高斯模糊一张图片，一般会有一个horizontal pass，
     一个vertical pass，就是说，我先水平处理一次所有像素，然后再垂直处理一遍。
     这里面，就是对图像中像素的一次统一处理，就是一个pass。放到shadow map里面，第一个pass就是要处理一次所有产生阴影的物体，
     是第一个shadow map的pass; 用第一个shadow map pass产生的贴图去绘制场景中产生的阴影，是第二个pass。
     这里面，对于场景的每一个模型用给定的渲染状态来进行一次drawcall处理，就是一个pass。
     因此，一个Tech，就是一个算法实现，一个pass，就是对一组数据的统一处理步骤。当然，个人理解而已。

     因此MTLRenderPassDescriptor 是不是次面上翻译成“渲染过程描述”
     
     */
    // Obtain a renderPassDescriptor generated from the view's drawable textures.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil)
    {
        // Create a render command encoder.
        /*
         MTLRenderCommandEncoder
         用于将图形渲染命令编码到MTLCommandBuffer（命令缓冲区）中
         */
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set the region of the drawable to draw into.(设置(画布)显示区域)
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0.0, 1.0 }];
        /*
         设置渲染管道，以保证顶点和片元两个shader会被调用
         id<MTLRenderPipelineState> _pipelineState 也就是该渲染过程中的核心事情（也就是对顶点，纹理做什么处理）
         */
        [renderEncoder setRenderPipelineState:_pipelineState];

        // Pass in the parameter data.
        [renderEncoder setVertexBytes:triangleVertices
                               length:sizeof(triangleVertices)
                              atIndex:AAPLVertexInputIndexVertices];
        
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:AAPLVertexInputIndexViewportSize];

        // Draw the triangle.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:3];

        [renderEncoder endEncoding];

        /* Schedule a present once the framebuffer is complete using the current drawable.
         * 显示在画布上（Drawable），view.currentDrawable 当前画布
         */
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // Finalize rendering here & push the command buffer to the GPU.
    [commandBuffer commit];
}

- (void)test {
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
}

@end
