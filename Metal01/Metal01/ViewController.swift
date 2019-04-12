//
//  ViewController.swift
//  Metal01
//
//  Created by admin on 2019/4/11.
//  Copyright © 2019 swinpa. All rights reserved.
//

import UIKit
import Metal
import MetalKit
//出处： https://juejin.im/post/59ad5d6551882539255b4809
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        /*
         Metal 中提供了 MTLDevice 的接口，代表了 GPU。
         MTLDevice 代表 GPU 的接口，提供了如下的能力：
         
            1.查询设备状态
            2.创建 buffer 和 texture
            3.指令转换和队列化渲染进行指令的计算

         */
        let device = MTLCreateSystemDefaultDevice()
        guard let gpu = device else {
            /*
             当设备不支持 Metal 的时候会返回空。
            */
            return
        }
        
        /*
         MTLCommandQueue
         有了 GPU 之后，我们需要一个渲染队列 MTLCommandQueue，队列是单一队列，确保了指令能够按顺序执行，
         里面存放的是将要渲染的指令 MTLCommandBuffer，这是个线程安全的队列，可以支持多个 CommandBuffer
         同时编码。 通过 MTLDevice 可以获取队列
         */
        let queue = gpu.makeCommandQueue()
        
        /*
         MTKView
         要用 Metal 来直接绘制的话，需要用特殊的界面 MTKView，同时给它设置对应的 device 为我们上面获取
         到 MTLDevice，并把它添加到当前的界面中。
         */
        
        let mtkView = MTKView.init(frame: self.view.bounds, device: gpu)
        self.view.addSubview(mtkView)
        
        /*
         渲染
         我们配置好 MTLDevice，MTLCommandQueue 和 MTKView 之后，我们开始准备需要渲染到界面上的内容了，
         就是要塞进队列中(MTLCommandQueue)的缓冲数据 MTLCommandBuffer 。
         简单的流程如下：
            1.先构造MTLCommandBuffer ，
            2.再配置 CommandEncoder ，包括配置资源文件，渲染管线等，
            3.再通过 CommandEncoder进行编码，
            4.最后才能提交到队列中去。
         
         MTLCommandBuffer
         有了队列之后，我们开始构建队列中的 MTLCommandBuffer，一开始获取的 Buffer 是空的，要通过
         MTLCommandEncoder 编码器来 Encode ，一个 Buffer 可以被多个 Encoder 进行编码。
         MTLCommandBuffer 是包含了多种类型的命令编码 - 根据不同的 编码器 决定 包含了哪些数据。
         通常情况下，app 的一帧就是渲染为一个单独的 Command Buffer。MTLCommandBuffer 是不支持重用的轻量级的对象，
         每次需要的时候都是获取一个新的 Buffer。
         Buffer 有方法可以 Label ，用来增加标签，方便调试时使用。
         临时对象，在执行之后，唯一有效的操作就是等到被执行或者完成的时候的回调，同步或者通过 block 回调，
         检查 buffer 的运行结果。
         
         创建MTLCommandBuffer的方法有:
            1.MTLCommandQueue - commandBuffer 方法 ，只能加到创建它的队列中。
            2.获取 retain 的对象 commandBufferWithUnretainedReferences 能够重用 一般不推荐

         */
        
        let commandBuffer = queue?.makeCommandBuffer()
        
        /*
         MTLCommandBuffer执行方式：
            1.enqueue 顺序执行
            2.commit 插队尽快执行 （如果前面有 commit 就还是排队等着）
         监听结果
         */
        
        commandBuffer?.addCompletedHandler { (buffer) in
        }
        commandBuffer?.waitUntilCompleted()
        
        commandBuffer?.addScheduledHandler { (buffer) in
        }
        commandBuffer?.waitUntilScheduled()
        
    }


}

