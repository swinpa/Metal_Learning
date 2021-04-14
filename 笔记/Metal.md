##Metal渲染过程 [参考文章](https://www.coderzhou.com/2019/02/02/Metal%E5%AD%A6%E4%B9%A0(%E4%BA%8C)%EF%BC%9A%E6%B8%B2%E6%9F%93%E8%BF%87%E7%A8%8B/)

![](https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Art/gfx-pipeline_2x.png)

读取顶点数据 —> 执行顶点着色器 —> 组装图元——光栅化图元 —> 执行片元着色器 —> 写入帧缓冲区 —> 显示到屏幕上。

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
 