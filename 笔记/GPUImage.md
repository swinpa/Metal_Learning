#GPUImage

####框架分为4部分

1. base
2. input
3. output
4. operation

###base
base中定义了一些基础相关的，输入输出相关的协议，纹理封装，着色器参数封装，以及其他一些类型封装（如color，size，position）
还有device，queue这些创建消耗大的对象，
#####重点在MetalRendering.swift中，在该文件中完成commandBuffer的encode，也就是在这里告诉GPU处理的纹理是什么，处理完存储在哪里（输出纹理）,对纹理需要怎么处理（需要执行什么着色器，着色器的参数是什么）

###input
input 定义了输入的一些操作，如：
	
	1.  PictureInput将image 转成纹理（MLTexture）,然后调用updateTargetsWithTexture来处理这个纹理（遍历targets中保存的滤镜，调用滤镜对纹理进行处理 ）
	2. MovieInput，按帧读取视频，将读取到的视频帧转成纹理，然后使用滤镜处理每一帧视频

###output
定义了输出的下一步操作（newTextureAvailable，因为滤镜也是输出，所以执行这方法时，滤镜会以当前输出的纹理作为下一个滤镜的输入纹理，对纹理进行处理）

定义了将纹理转image并保存在指定URL下

###Operation

定义了各种滤镜以及着色器

#####跟GPU渲染流程相关的主要在BasicOperation

各滤镜init 时指定了顶点着色器以及片段着色器，根据指定的着色器创建MTLRenderPipelineState 对象

#####重点在newTextureAvailable方法，获取滤镜输入的纹理，然后跑GPU渲染流程：
	创建commandBuffer -> 编码（MTLRenderCommandEncoder）commandBuffer -> commandBuffer.commit()

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
 