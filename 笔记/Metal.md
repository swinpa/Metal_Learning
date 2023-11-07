##Metal渲染过程 [参考文章](https://www.coderzhou.com/2019/02/02/Metal%E5%AD%A6%E4%B9%A0(%E4%BA%8C)%EF%BC%9A%E6%B8%B2%E6%9F%93%E8%BF%87%E7%A8%8B/) | [专栏 -- iOS 图像处理](https://xiaozhuanlan.com/topic/1287954630)

![](https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Art/gfx-pipeline_2x.png)

读取顶点数据 —> 执行顶点着色器 —> 图元装配——光栅化图元 —> 执行片元着色器 —> 写入帧缓冲区 —> 显示到屏幕上。


##执行顶点着色器
接收一组顶点数据数组，每个顶点执行一次运算，计算该顶点的坐标，颜色，光照，纹理坐标等，在渲染管线中每个顶点都是独立地被执行。每个图元由一个或者多个顶点组成，每个顶点定义一个点，一条边的一端或者三角形的一个角。每个顶点关联一些数据，这些数据包括顶点坐标，颜色，法向量以及纹理坐标等。所有这些顶点相关的信息就构成顶点数据。

##图元装配
图元装配(Primitive Assembly)阶段将顶点着色器输出的所有顶点作为输入（如果是GL_POINTS，那么就是一个顶点），并所有的点装配成指定图元的形状。
	
	为了让系统知道我们的坐标和颜色值构成的到底是什么，需要你去指定这些数据所表示的渲染类型。
	我们是希望把这些数据渲染成一个点？一个三角形？还是仅仅是一个长长的线？做出的这些提示叫做图元。

##光栅化(Rasterization)
在光栅化阶段，基本图元被转换为供片段着色器使用的片段。简单来说，就是将数据转化成可见像素的过程。在片段着色器运行之前会执行裁切(Clipping)。裁切会丢弃超出你的视图以外的所有像素，用来提升执行效率。在Metal中，这一步是用户控制不了的，由系统自动处理

	简单来说，就是将数据转化成可见像素的过程，丢弃超出你的视图以外的所有像素

##执行片元着色器
片段着色器的主要作用是计算一个像素的最终颜色
在片段着色器之前的阶段，渲染管线都只是在和顶点，图元打交道。片段着色器可以根据顶点着色器输出的顶点纹理坐标对纹理进行采样(从纹理坐标获取纹理颜色叫做采样(Sampling))，以计算该片段的颜色值。从而调整成各种各样不同的效果图，这也是所有OpenGL或Metal高级效果产生的地方
片段着色器的返回值是一个四维向量，即是这个片元的颜色 RGBA 值
	
	简单的说就是给像素指定颜色值
	
##代码流程
以《眼睛放大》效果为例子渲染代码组织流程简单概括就是：
	
	1. 创建一个视图，用来展示结果图（这个可以忽略，结果不一定需要展示）
	2. 提供原图，以供进行效果处理
	3. 提供原图中，眼睛区域，以便指定区域进行处理
	4. 提供眼睛放大的处理算法
	5. 提交给 GPU 处理
	6. 视图显示处理完的结果图

而这几步，正是我们和 GPU 交互的具体描述。用 Metal 描述如下：
![](https://images.xiaozhuanlan.com/photo/2018/30708e590a6e523ec212de678d5e608d.png)

具体到代码

```
let device: MTLDevice = MTLCreateSystemDefaultDevice()
let commandQueue: MTLCommandQueue = device.makeCommandQueue()
let commandBuffer = commandQueue.makeCommandBuffer() 
commandBuffer.commit()
```
上面这几步就完成了大概过程，具体需要GPU处理什么纹理(目标)，怎么处理(着色器)，则就需要在commandBuffer中告诉GPU，（通过MTLCommandEncoder将这些信息与commandBuffer关联）
#####1. 准备渲染目标纹理(图片)
```
let textureLoader: MTKTextureLoader = MTKTextureLoader(device: device)
let imageTexture = try textureLoader.newTexture(cgImage: image, options: [MTKTextureLoader.Option.SRGB : false])
```
#####2. 准备渲染过程中用到的顶点着色器(vertexFunction),片段着色器(fragmentFunction),以及像素格式pixelFormat

```
let defaultLibrary = try device.makeLibrary(filepath:metalLibraryPath)
let fragmentFunction = defaultLibrary.makeFunction(name: fragmentFunctionName)    
let descriptor = MTLRenderPipelineDescriptor()
descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
descriptor.vertexFunction = vertexFunction
descriptor.fragmentFunction = fragmentFunction
let renderPipelineState = device.makeRenderPipelineState(descriptor: descriptor)

```

#####3. 准备渲染处理结束后存储在哪里(输出纹理outputTexture)

```
let renderPass = MTLRenderPassDescriptor()
renderPass.colorAttachments[0].texture = outputTexture.texture
renderPass.colorAttachments[0].clearColor = clearColor
renderPass.colorAttachments[0].storeAction = .store
renderPass.colorAttachments[0].loadAction = .clear
        
```
#####4. 通过MTLRenderCommandEncoder将前面的目标纹理(imageTexture 也就是图片)，怎么处理(着色器)，输出纹理outputTexture与commandBuffer关联起来

```
let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)        
renderEncoder.setFrontFacing(.counterClockwise)
//设置着色器
renderEncoder.setRenderPipelineState(pipelineState)
//设置顶点着色器的参数
renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//设置需要处理的纹理
renderEncoder.setFragmentTexture(imageTexture, index: textureIndex)
//设置片段着色器的参数
let uniformBuffer = device.makeBuffer(bytes: uniformValues,//比如lookup图的纹理，或者亮度，饱和度等待
                                                                length: uniformValues.count * MemoryLayout<Float>.size,
                                                                options: [])!
renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: imageVertices.count / 2)
/*
Declares that all command generation from the encoder is completed.
After endEncoding is called, the command encoder has no further use. You cannot encode any other commands with this encoder.
也就是encode 完成，后面就可以提交到queue中了
*/
renderEncoder.endEncoding()
```

#####总结一下就是：
	
	GPU有一个command queue，queue中的元素是command buffer，它会从这个queue中获取command ，
	并根据这个command的描述执行操作。
	command buffer描述了GPU执行的参数，比如输入的纹理是什么（也就是需要对谁做处理），纹理格式是什么
	怎么做（顶点着色器是什么，片段着色器是什么）。处理完输出又是什么


##GPUImage 执行流程

1. 初始化输入(图片输入)PictureInput(image:UIImage(named:"WID-small.jpg")!)
2. 初始化滤镜（可以多个形成一个滤镜链）

	```
	let lookuptable = PictureInput(image:UIImage(named:"lookupTable.jpg")!)
	filter = LookupFilter.init()
	filter.lookupImage = lookuptable
	```
	滤镜在初始化的时候会创建好GPU在渲染过程中需要的MTLRenderPipelineState对象，
   MTLRenderPipelineState需要指定的descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction都会从滤镜初始化时传进来，并且准备好
    顶点着色器，片段着色器需要的参数
3. 初始化输出（可以直接渲染到View上，可以是PictureOutput图片，也可以是MovieOutput视频）
4. 使用 -> 符号将输入，滤镜，输出串联起来形成一条链
	
	PictureInput -> LookupFilter -> PictureOutput
5. 开始处理 PictureInput.processImage()
 
