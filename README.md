# 并发编程 -- 并发性和应用程序设计

在计算机发展初期，计算机可以执行的每单位时间的最大工作量取决于CPU的频率。但随着技术进步和处理器设计变得更加紧凑，热量和其他物理约束开始限制处理器的最大频率。因此，芯片制造商寻找其他方法来提高芯片的整体性能。他们的解决方案是增加每个芯片上处理器内核的数量。通过增加内核数量，单个芯片每秒可以执行更多指令，而不会增加CPU速率或者改变芯片尺寸或热特性。唯一的问题是如何利用额外的内核。

为了利用多个内核，计算机需要能够同时完成多项任务的软件。对于像OS X或者iOS这样的现代多任务操作系统，在任何给定的时间都可以运行一百或者更多个程序，因此将每个程序安排到不同的内核中应该是可能的。然而，这些程序中的大多数都是系统守护进程和后台应用程序，这些应用程序实际处理时间非常短。相反，真正需要的是个别应用程序更有效地利用额外内核的方式。

所以，为了总结这个问题，需要一种方法让应用程序利用可变数量的计算机内核。单个应用程序执行的工作量也需要能够动态扩展以适应不断变化的系统条件。解决方案必须足够简单，以免增加利用这些内核所需的工作量。好消息是苹果的操作系统为所有这些问题提供了解决方案，本章将介绍构成该解决方案的技术以及可以对代码进行设计调整以利用它们。


## 抛弃线程

虽然线程已经存在了很多年，并且仍然有其用处，但它们并没有解决以可扩展的方式执行多个任务的一般问题。使用线程，创建可扩展解决方案的负担落在了开发者的肩膀上。开发者必须决定创建多少个线程并根据系统条件的变化动态调整该数量。另一个问题是，应用程序承担与创建和维护其使用的任何线程相关的大部分代价。

OS X和iOS是采用异步设计方法来解决并发问题的，不是依赖线程。异步函数已经存在于操作系统中很多年了，通常用于执行可能需要很长时间的任务，例如从磁盘中读取数据。异步函数被调用时，会在后台做一些工作来开始执行一个任务，但在该任务实际完成之前就返回。在过去，如果一个异步函数不存在你想要做的事情，开发者将不得不编写自己的异步函数并创建自己的线程。但是现在，OS X和iOS提供的技术允许开发者异步执行任何任务，而无需自己管理线程。

Grand Central Dispatch (GCD) 是异步执行任务的技术之一。该技术采用开发者在应用程序中编写的线程管理代码，并将该代码移至系统级别。开发者只需要定义要执行的任务并将其添加到适当的dispatch queues（调度队列）中即可。GCD负责创建所需的线程并安排任务在这些线程上运行。由于线程管理现在是系统的一部分，因此GCD提供了一种全面的任务管理和执行方法，比传统线程提供更高的效率。

Operation queues（操作队列）是与dispatch queues非常类似的Objective-C对象。开发者定义要执行的任务，然后将其添加到operation queues中。像GCD一样，operation queues为开发者处理所有线程管理，确保在系统上尽可能快速和高效地执行任务。

以下各节描述了有关dispatch queues、operation queues以及可在应用程序中使用的其他一些有关异步技术的更多信息。

### Dispatch Queues

Dispatch queues是一种基于C语言的机制，能够用来执行自定义任务。dispatch queue可以串行或并行执行任务，但始终按先进先出的顺序执行（换句话说，dispatch queue总是按照任务被添加到队列的顺序启动任务，并以相同顺序推出任务）。serial dispatch queue（串行调度队列）一次一次只运行一个任务，直到该任务完成之后才执行下一个新任务。相比之下，concurrent dispatch queue（并行调度队列）会尽可能多地运行任务，而无需等待正在运行的任务执行完毕。

Dispatch queues还有其他益处：
- 它们提供了一个直截了当和简单的编程接口。
- 它们提供自动和全面的线程池管理。
- 它们提供了协调组装的速度。
- 它们的内存效率要高得多（因为线程栈并不存储于应用程序的内存中）。
- 它们不会陷入负载下的内核。
- 将任务异步调度到dispatch queue不会造成队列死锁。

