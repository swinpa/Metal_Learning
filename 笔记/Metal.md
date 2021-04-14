##Metal渲染过程 [参考文章](https://www.coderzhou.com/2019/02/02/Metal%E5%AD%A6%E4%B9%A0(%E4%BA%8C)%EF%BC%9A%E6%B8%B2%E6%9F%93%E8%BF%87%E7%A8%8B/)

![](https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Art/gfx-pipeline_2x.png)
读取顶点数据 —> 执行顶点着色器 —> 组装图元——光栅化图元 —> 执行片元着色器 —> 写入帧缓冲区 —> 显示到屏幕上。