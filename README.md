# iOS并发编程 -- 并发性和应用程序设计

在计算机发展初期，计算机可以执行的每单位时间的最大工作量取决于CPU的频率。但随着技术进步和处理器设计变得更加紧凑，热量和其他物理约束开始限制处理器的最大频率。因此，芯片制造商寻找其他方法来提高芯片的整体性能。他们的解决方案是增加每个芯片上处理器内核的数量。通过增加内核数量，单个芯片每秒可以执行更多指令，而不会增加CPU频率或者改变芯片尺寸或热特性。唯一的问题是如何利用额外的内核。

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
- 将任务异步调度到dispatch queue不会死锁队列。
- 它们的伸缩性更强。
- 串行调度队列为锁和其他同步原函数提供了更高效的替代方案。

提交给dispatch queue的任务必须封装在函数或者block对象中。block对象是OS X v10.6和iOS 4.0中引入的一种C语言特性，它在概念上类似于函数指针，但有一些额外的好处。通常在其他函数或方法中定义block，以便可以从该函数或方法访问其他变量。block也能被移出栈区并复制到堆区，这是将它们提交给dispatch queue时所发生的情况。所有这些语义都可以用较少的代码实现非常动态的任务。

Dispatch queues是Grand Central Dispatch技术的一部分，是C语言运行时的一部分。有关在应用程序中使用dispatch queue的更多信息，请参看[iOS并发编程 -- Dispatch Queues](https://www.jianshu.com/p/4533e653d49f)。有关block及其优点的更多信息，请参看[Block编程指南](https://www.jianshu.com/p/c1c03ae5a6a5)。

### Dispatch Sources

Dispatch sources（调度源）是一种基于C语言的机制，其用于异步处理特定类型的系统事件。dispatch source封装了有关特定类型系统事件的信息，并在发生该事件时将特定block对象或者函数提交给dispatch queue。可以使用dispatch source来监视以下类型的系统事件：
- Timers
- Signal handles
- Descriptor-related events
- Process-related events
- Mach port events
- Custom events that you trigger

Dispatch sources是Grand Central Dispatch技术的一部分。有关使用dispatch source在应用程序中接收事件的信息，请参看[iOS并发编程 -- Dispatch sources](https://www.jianshu.com/p/6508aaf2df4e)。

### Operation Queues

Operation Queue（操作队列）是concurrent dispatch queue的Cocoa同等技术，由`NSOperationQueue`实现。dispatch queue总是按照先进先出的顺序执行任务，而operation queue在确定任务的执行顺序时会考虑其他因素。这些因素中最主要的是给定的任务是否取决于其他任务的完成。可以在定义任务时配置依赖关系，并可以使用它们为任务创建复杂的执行顺序图。

提交给operation queue的任务必须是`NSOperation`类的实例。operation对象是一个Objective-C对象，其封装了想要执行的任务以及执行它所需要的任何数据。由于`NSOperation`类本质上是一个抽象基类，因此通常会定义自定义子类来执行任务。但是，Foundation框架确实包含了一些可以创建和使用的具体子类来执行任务。

Operation对象会生成键-值观观察（KVO）通知，这是监视任务进度的有效方法。**虽然operation queue总是并行执行操作，但可以使用依赖关系来确保在需要时它们被串行执行。**

有关如何使用operation queue的更多信息以及如何自定义operation对象的更多信息，请参看[iOS并发编程 -- Operation Queues](https://www.jianshu.com/p/65ab102cac60)。

## 异步设计技术

在考虑重新设计代码以支持并发之前，应该确定一下是否需要这样做。在确保主线程可以自由地响应用户事件的情况下，并发可以提高代码的响应速度。它甚至可以通过利用更多内核在相同的时间内完成更多工作来提高代码的效率。但是，它也增加了开销以及代码的整体复杂性，使得编写和调试代码变得更加困难。

因为其增加了复杂性，所以并发不是在产品周期结束时可以移植到应用程序中的功能。要做到这一点，需要仔细考虑仔细考虑应用程序执行的任务以及用于执行这些任务的数据结构。如果使用方式不正确，可能会使代码的运行速度比以前更慢，并且对用户的响应性较差。因此，在设计周期的开始阶段花点时间设定一些目标并考虑需要采取的方法是值得的。

### 定义应用程序的预期行为

在考虑为应用程序添加并发性之前，应该首先定义什么才是应用程序的正确行为。了解应用程序的预期行为能够在之后验证此设计。还应该了解一下在引入并发后可能带来的预期性能优势。

首先该做的第一件事是列举出应用程序执行的任务以及与每个任务关联的对象或数据结构。最初，我们可能希望从用户选择菜单项或者单击按钮执行的任务开始。这些任务提供不连续的行为，并具有明确定义的开始和结束点。还应该列举应用程序可能执行的其他类型的无需用户交互的任务，例如基于定时器的任务。

在获得高级别任务列表后，开始将每个任务进一步分解为必须采取的一系列步骤，以便成功完成任务。在这个级别上，应该主要关注需要对任何数据结构和对象进行的修改以及这些修改如何影响应用程序的整体状态。还要注意对象和数据结构之间的依赖关系。例如，如果任务涉及对对象数组进行相同的更改，则值得注意的是对一个对象的更改是否会影响任何其他对象。如果这些对象可以彼此独立地进行修改，那么这可能是可以同时进行这些修改的地方。

### 分解出可执行的工作单元

从我们对应用程序任务的理解中，我们应该已经能够确定代码可能从并发中受益的地方。如果更改任务重一个或者多个步骤的顺序会改变结果，则可能需要继续串行执行这些步骤。但是如果更改顺序对结果没有任何影响，则应考虑并行执行这些步骤。在这两种情况下，我们都要定义代表需要执行的一个或多个步骤的可执行工作单元。然后使用block对象或者operation对象封装这个工作单元并调度到合适的队列中。

对于我们确定的每个可执行工作单元，不用太担心正在执行的任务总量，至少在最初是如此。尽管转换线程消耗较大，但dispatch queue和operation queue的优点之一是，在许多情况下，这些成本比传统线程要小得多。因此，使用队列可以比使用线程更有效地执行更小的工作单元。当然，我们应该始终衡量实际结果并根据需要调整任务的大小，但最初不应将任务考虑太小。

### 确定需要的队列

现在任务已被分解为不同的工作单元并使用block对象或者operation对象进行了封装，我们需要定义要用于执行该代码的队列。对于给定的任务，请检查创建的block对象或者operation对象以及它们必须被执行的顺序，确保正确执行任务。

如果使用block来实现任务，则可以将block添加到serial dispatch queue或concurrent dispatch queue中。如果需要特定的顺序执行这些block，则应该将它们添加到serial dispatch queue中。如果不需要以特定的顺序执行，则可以将这些block添加到concurrent dispatch queue中，或根据需要将它们添加到几个不同的dispatch queue中。

如果使用operation对象来实现任务，要串行执行这些operation对象，必须配置相关对象之间的依赖关系。依赖性阻止一个operation对象执行，直到它所依赖的对象完成其工作。

### 提高效率的几点提示

除了简单地将代码分解为更小的任务并将其添加到队列之外，还有其他一些方法可以提高使用队列的代码的整体效率：
- **如果内存使用率是一个因素，请考虑直接在任务中计算值。** 如果应用程序已经绑定了内存，现在直接计算值可能比从主内存加载缓存值更快。使用给定处理器内核的寄存器和高速缓存直接计算值比主内存要快得多。
- **提前确定串行任务，并尽可能使它们更加并发。** 如果一个任务必须串行执行是因为其依赖于某个共享资源，请考虑更改体系结构来移除该共享资源。
- **避免使用锁。** 在大多数情况下，dispatch queue和operation queue提供的支持不需要锁。不是使用锁来保护某些共享资源，而是指定一个串行队列（或者使用operation对象依赖性）以正确的顺序执行任务。
- **尽可能依赖系统框架。** 实现并发的最好方法是利用系统框架提供的内置并发。许多框架在内部使用线程和其他技术来实现并发行为。在定义任务时，看看现有的框架是否定义了一个功能或方法能够完全实现需要的功能或方法并可以并行执行。使用该API可以节省我们的工作量，并且更有可能为我们提供最大的并发可能性。

## 性能影响

Operation queues，dispatch queues，和dispatch sources使我们可以更轻松地同时执行更多代码。但是，这些技术并不能保证提高应用程序的效率或响应速度。我们仍然有责任以满足需求的方式来使用队列，并不该对应用程序的其他资源施加过度负担。例如，虽然可以创建10000个operation对象并将它们提交到operation queue中，但这样做会导致应用程序可能分配一个巨大的内存量，这可能会导致分页并降低性能。

在代码中引入任何数量的并发之前（无论使用队列还是线程），都应该收集一组反映应用程序当前性能的基准指标。在执行更改后，应该收集其他指标并将其与基准进行比较，以查看应用程序的整体效率是否有所提高。如果并发性的引入使应用程序运行效率降低或响应速度变慢，则应使用可用的性能检测工具来查找可能的原因。

有关性能和可用性能工具的介绍，以及指向更高级性能相关主体的链接，请参看[Performance Overview](https://developer.apple.com/library/content/documentation/Performance/Conceptual/PerformanceOverview/Introduction/Introduction.html#//apple_ref/doc/uid/TP40001410)。

## 并发和其他技术

将代码分解为模块化任务是尝试和提高应用程序并发量的最佳方式。但是，这种设计方法可能无法满足每种情况下每个应用程序的需求。根据我们的任务，可能还有其他选项可用提高应用程序的整体并发性。本节概述了作为设计的一部分可以考虑使用的其他一些技术。

### OpenCL和并发

在OS X中，Open Computing Language （OpenCL）是一种基于标准的技术，用于在计算机的图形处理器上执行通用计算。如果有一个明确的应用于大型数据集的计算集，则OpenCL是一种很好的技术。例如，可以使用OpenCL对图像的像素执行滤波计算，或使用使用它一次执行对多个值的复杂数学计算。换句话说，OpenCL更适合于可以并行操作数据的问题集。

尽管OpenCL适合执行大规模数据并行操作，但不适合更通用的计算。准备并将数据和所需的工作内核传输到图形卡以使其可以通过GPU进行操作需要花费大量精力。同样，检索OpenCL生成的任何结果也需要花费大量精力。因此，与系统交互的任何任务通常都不推荐使用OpenCL。例如，不会使用OpenCL处理来自文件或网络流的数据。相反，使用OpenCL执行的工作必须更加独立，才能将其转移到图形处理器并独立计算。

有关OpenCL的更多信息以及如何使用它，请参看Mac版[OpenCL Programming Guide](https://developer.apple.com/library/content/documentation/Performance/Conceptual/OpenCL_MacProgGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008312)。

### 何时使用线程

尽管operation queue和dispatch queue是并行执行任务的首选方式，但它们不是万能的。根据我们的应用程序，我们有时可能仍然需要创建自定义线程。如果确实需要创建自定义线程，那么应该努力创建尽可能少的线程，并且应该仅将这些线程用于无法以其他方式实现的特定任务。

线程仍然是必须实时运行的代码的好方式。Dispatch queue尽可能快地运行它们的任务，但它们不能解决实时限制。如果需要在后台运行的代码具有更多可预测的行为，那么线程仍然可以提供更好的选择。

与任何线程编程一样，应该总是明智地使用线程，并且只有在绝对有必要时才使用线程。有关线程组件的更多信息以及如何使用它们，请参看[Threading Programming Guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Multithreading/Introduction/Introduction.html#//apple_ref/doc/uid/10000057i)。


# iOS并发编程 -- Operation Queues

Cocoa operation以一种面向对象的方式来封装需要异步执行的工作，operation被设计为与operation queue一起使用或者单独使用。因为它们基于Objective-C，所以OS X和iOS中基于Cocoa的应用程序最常使用它们。

## 关于Operation对象

operation对象是`NSOperation`类的实例，用于封装希望应用程序执行的工作。`NSOperation`类本身是一个抽象类，为了做任何有用的工作，其必须被分类。尽管是抽象的，但该类确实提供了大量的基础设施来尽量减少我们在自己的子类中要完成的工作量。另外，Foundation框架提供了两个具体的子类，我们可以使用现有代码使用它们。下表列出了这些类以及如何使用每个类的描述。

| Class | Description |
|--------|--------------|
| NSInvocationOperation | 使用该类基于应用程序中的对象和方法选择器来创建operation对象。当存在一个执行所需任务的方法时，则可以使用此类。因为它不需要子类化，所以可以使用此类以更动态的方式创建operation对象。|
| NSBlockOperation | 使用该类并行执行一个或多个block对象。因为它可以执行多个block，所以block operation对象使用一组语义来操作。只有当所有关联的block已经完成执行时，操作本身才算完成。 |
| NSOperation | 该类是用于自定义operation对象的基类。通过子类化NSOperation，我们可以完全控制自己操作的实现，包括更改操作执行的默认方式并报告其状态的功能。 |

所有operation对象都支持以下主要功能：
- 支持在operation对象之间建立基于图形的依赖关系。这些依赖关系会阻止给定的操作运行，直到它所依赖的所有操作都已完成运行。
- 支持可选的完成block，该block在操作的主任务完成后执行（仅限OS X v10.6及更高版本）。
- 支持使用KVO通知监听对操作执行状态的更改。
- 支持对操作进行优先级排序，从而影响其相对执行顺序。
- 支持取消正在执行的操作。

operation旨在帮助提高应用程序中的并发水平。operation也是将应用程序行为组织和封装为简单离散块的好方式。可以将一个或多个operation对象提交给一个队列，并让相应的工作在一个或者多个单独的线程上异步执行，而不是在应用程序的主线程上运行一些代码。

## 并发与非并发操作

虽然通常通过将操作添加到操作队列来执行操作，但这不是必需的。也可以通过调用操作对象的`start`方法手动执行操作，但这样做并不能保证该操作与其他代码同时运行。`NSOperation`类的`isConcurrent`方法会告知我们一个操作相对于调用`start`方法的线程是同步还是异步运行的。默认情况下，此方法返回`NO`，这意味着该操作在调用线程中同步运行。

如果想实现一个并发操作，必须编写额外的代码来异步启动操作。例如，我们可能会创建一个单独的线程，调用异步系统函数或执行其他任何操作来确保`start`方法启动任务并立即返回，并且很可能在任务完成之前返回。

大多数开发者应该永远不需要实现并发操作对象。如果始终将操作添加到操作队列中，则不需要实现并发操作对象。当向操作队列提交非并发操作时，队列本身会创建一个线程来运行这些操作。因此，操作队列添加非并发操作队列仍然会导致异步执行操作对象代码。只有在需要异步执行操作而不将其添加到操作队列的情况下，才需要定义并发操作的能力。

## 创建NSInvocationOperation对象

`NSInvocationOperation`类是`NSOperation`的具体子类，它在运行时会调用指定的关联对象的方法。使用此类可以避免为应用程序中的每个任务自定义大量的operation对象。特别是如果我们需要修改现有的应用程序并且已经拥有执行必要任务所需的对方和方法。当我们想要调用的方法可以根据具体情况而改变时，可以选择使用该类。例如，可以使用调用操作来执行基于用户输入动态选择的方法选择器。

创建一个`NSInvocationOperation`对象的过程非常简单。可以创建并初始化类的新实例，将所需的对象和方法选择器传递给初始化方法。以下代码显示了自定义类中的两个方法，用于演示创建过程。`taskWithData:`方法创建一个新的调用对象并为其提供另一个方法的名称，该方法包含任务的实现。
```
- (NSOperation*)taskWithData:(id)data
{
    NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(myTaskMethod:) object:data];

    return theOp;
}

// This is the method that does the actual work of the task.
- (void)myTaskMethod:(id)data
{
    // Perform the task.
}
@end
```

## 创建一个NSBlockOperation对象

`NSBlockOperation`类是`NSOperation`的具体子类，充当一个或多个block对象的包装。此类为已经已经使用操作队列并且不想创建调度队列的应用程序提供面向对象的包装器。还可以使用block操作来利用操作依赖关系、KVO 以及可能不适用于调度队列的其他功能。

在创建一个block操作时，通常在初始化时至少添加一个block，并在稍后根据需要添加更多block。当需要执行`NSBlockOperation`对象时，该操作对象将其所有block对象提交给默认优先级的并发调度队列（concurrent dispatch queue）。操作对象会等待所有block完成执行，当最后一个block完成执行时，操作对象将自身标记为已完成。因此，我们可以使用block操作来跟踪一组正在执行的block，就像使用线程连接合并多个线程的结果一样。区别在于，**因为block操作本身在单独的线程上运行，所以应用程序的其他线程可以在等待block操作完成的同时继续工作。**

以下代码显示了如何创建一个`NSBlockOperation`对象的简单示例。该block本身没有参数并且没有返回结果。
```
NSBlockOperation* theOp = [NSBlockOperation blockOperationWithBlock: ^{

    NSLog(@"Beginning operation.\n");
    // Do some work.
}];
```
创建block操作对象后，可以使用`addExecutionBlock:`方法向其添加更多block。如果需要连续执行block，则必须将它们直接提交到所需的调度队列。

## 定义一个自定义操作对象

如果block操作和invocation操作对象不能完全满足应用程序的需求，则可以直接子类化`NSOperation`并添加所需的任何行为。`NSOperation`类为所有操作对象提供了一个通用的继承点。该类还提供了大量的基础设施来处理依赖关系和KVO通知所需的大部分工作。但是，我们可能还需要补充现有的基础设施，以确保我们的操作正确。必须执行的额外工作量取决于我们是在执行非并发还是并发操作。

定义非并发操作比定义并发操作简单得多。对于非并发操作，只需执行主要任务并对取消事件作出对应的响应。现有的类级别的基础设施为我们完成了所有其他工作。对于并发操作，必须用我们的自定义代码替换一些现有的基础架构。以下部分展示了如何实现这两种类型的对象。

### 执行主要任务

每个操作对象至少应该实现以下方法：
- 自定义初始化方法。
- `main`方法。

我们需要一个自定义的初始化方法来将操作对象设置为已知状态，还需要自定义`main`方法来执行我们的任务。还可以根据需要实现其他方法，如下所示：
- 计划在`main`方法的实现中调用的自定义方法。
- 用于设置数据值和访问操作结果的访问器方法。
- 允许我们归档和反归档操作对象的NSCoding协议方法。

以下代码展示了一个自定义`NSOperation`子类的初始模版。（以下代码并未展示如何取消正在执行的操作，只展示了我们通常会使用的方法。有关如何取消操作的信息，请参看[响应取消事件](jump)。）此类的初始化方法将单个对象用作数据参数，并存储对操作对象的引用。在将结果返回给应用程序之前，`main`方法将处理该数据对象。
```
@interface MyNonConcurrentOperation : NSOperation

@property id (strong) myData;

-(id)initWithData:(id)data;

@end

@implementation MyNonConcurrentOperation

- (id)initWithData:(id)data {
    if (self = [super init])
    myData = data;
    return self;
}

-(void)main {
    @try {
        // Do some work on myData and report the results.
    }
    @catch(...) {
        // Do not rethrow exceptions.
    }
}
@end
```

有关如何实现`NSOperation`子类的详细示例，请参看[NSOperationSample](https://developer.apple.com/library/content/samplecode/NSOperationSample/Introduction/Intro.html#//apple_ref/doc/uid/DTS10004184)。

### 响应取消事件

在一个操作开始执行之后，其会执行它的任务直到完成或者我们使用代码明确地取消操作。即使在操作开始执行之前，取消也可能随时发生。尽管`NSOperation`类为我们提供了一种取消操作的方法，但要意识到取消事件是自愿行为。如果一个操作被彻底终止，可能无法收回已分配的资源。因此，操作对象需要检查取消事件，并在操作过程中正常退出。

为了支持操作对象中的取消操作，只需要定期在自定义代码中调用操作对象的`isCancelled`方法，并在该方法返回`YES`时立即执行`return`操作。无论操作的持续时间如何重要或者是直接子类化`NSOperation`还是使用其中一个具体的子类，支持取消操作都很重要。`isCancelled`方法本身非常轻量级，可以频繁调用而不会有任何明显的性能损失。在设计操作对象时，应考虑在代码中以下位置调用`isCancelled`方法：
- 在执行任何实际的工作之前。
- 在循环的每次迭代中至少一次，或者如果每次迭代相对较长，则更频繁。
- 在代码中相对容易退出操作的任何地方。

以下代码提供了一个非常简单的例子来说明如何在操作对象的`main`方法中响应取消事件。在这种情况下，每一次while循环都会调用`isCancelled`方法，允许在工作开始之前快速退出操作并且每隔一段时间再次执行一次。
```
- (void)main {
    @try {
        BOOL isDone = NO;

        while (![self isCancelled] && !isDone) {
            // Do some work and set isDone to YES when finished
        }
    }
    @catch(...) {
        // Do not rethrow exceptions.
    }
}
```
虽然以上示例中没有执行清理的代码，但我们在实现时应该确保释放由我们的自定义代码分配的任何资源。

### 配置操作以支持并发执行

操作对象默认以同步方式执行，也就是说它们在调用其启动方法的线程中执行它们的任务。因为操作队列会为非并发操作对象提供线程，但大多数操作对象仍然是异步运行的。然而，如果我们计划手动执行操作对象并仍然希望它们异步执行，则必须采取适当的操作以确保它们可以运行。可以通过将操作对象定义为并发操作来完成此操作。

下表列出了通常为了实现并发操作而重写的方法。

| Method | Description |
|----------|---------------|
| start | （必需）所有并发操作都必须重写此方法，并用它们自己的自定义实现替换默认行为。要手动执行操作，请调用其`start`方法。因此，此方法的实现是自定义操作的起点，并且是设置执行任务的线程或者其他执行环境的位置。在自定义实现中，不能调用`super`。 |
| main | （可选）此方法通常用于实现与操作对象关联的任务。虽然可以在`start`方法中执行任务，但使用此方法执行任务可以使设置和任务代码更清晰地分离。 |
| isExecuting<br>isFinished | （必需）并发操作负责设置其执行环境并向外部报告该环境的状态。因此，并发操作必须保存一些状态信息，以知道它如何执行任务以及何时完成该任务。它必须使用这些方法报告该状态。<br>这些方法的实现必须是线程安全的，以便同时从其他线程调用。更改这些方法报告的值时，还必须按照预期的键路径生成对应的KVO通知。 |
| isConcurrent | （必需）要将操作标识为并发操作，请覆写方法并返回`YES`。 |

本节的余下部分显示了MyOperation类的示例实现，其演示了实现并发操作所需的基本代码。MyOperation类只是在它创建的单独线程上执行自己的`main`方法。`main`方法执行的实际工作师无关紧要的。示例的要点是要演示定义并发操作时需要提供的基础架构。

以下代码显示了MyOperation类的接口和部分实现。MyOperation类的`isConcurrent`、`isExecuting`和`isFinished`方法的实现相对简单。`isConcurrent`方法应该简单地返回`YES`来表明这是一个并发操作。`isExecuting`和`isFinished`方法只是返回存储在类本身的实例变量中的值。
```
@interface MyOperation : NSOperation {
BOOL        executing;
BOOL        finished;
}
- (void)completeOperation;
@end

@implementation MyOperation
- (id)init {
    self = [super init];
    if (self) {
        executing = NO;
        finished = NO;
    }
    return self;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}
@end
```
以下代码显示了MyOperation类的`start`方法。该方法的实现很少，以便演示绝对必须执行的任务。在这种情况下，该方法只需启动一个新线程并配置该线程调用`main`方法。该方法还更新`executing`成员变量，并为`isExecuting`键路径生成KVO通知以反映该值的变化。
```
- (void)start {
    // Always check for cancellation before launching the task.
    if ([self isCancelled])
    {
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }

    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}
```
以下代码显示了MyOperation类的其余实现。如上代码所示，`main`方法是新线程的入口点。它执行与操作对象关联的任务，并在该任务最终完成时调用自定义`completeOperation`方法，`completeOperation`方法然后为`isExecuting`和`isFinished`键路径生成所需的KVO通知，以反映操作状态的变化。
```
- (void)main {
    @try {

        // Do the main work of the operation here.

        [self completeOperation];
    }
    @catch(...) {
        // Do not rethrow exceptions.
    }
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    executing = NO;
    finished = YES;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
```
即使操作被取消，也应该始终通知KVO观察者操作对象现在已完成其工作。当操作对象依赖于其他操作对象的完成时，它会监听这些对象的`isFinished`键路径。只有当所有的对象都报告它们已经完成时，才会执行相关的操作信号，表明它已准备好运行。生成完成通知失败，可能会因此阻止应用程序中其他操作的执行。

### 维护KVO合规性

`NSOperation`类兼容了对以下键路径的键-值观察（KVO）：
- isCancelled
- isConcurrent
- isExecuting
- isReady
- dependencies
- queuePriority
- completionBlock

如果覆写`start`方法或者对`NSOperation`对象进行除了重写`main`方法之外的任何重要定制，则必须确保定制对象对这些键路径保持KVO兼容。当覆写`start`方法时，最应该考虑的键路径应该是`isExecuting`和`isFinished`，这些是重新实现该方法时最常受影响的键路径。

如果要实现对自定义依赖项（并非其他操作对象）的支持，还可以重写`isReady`方法，并强制它返回`NO`，直到满足自定义依赖项为止。（如果要实现自定义依赖项，同时仍然支持由`NSOperation`类提供的默认依赖项管理系统，请确保在`isReady`方法调用`super`。）当操作对象的准备状态更改时，为`isReady`键路径生成KVO通知报告这些变化。除非重写`addDependency:`或者`removeDependency:`方法，否则不需要担心为依赖键路径生成KVO通知。

虽然可以为`NSOperation`的其他键路径生成KVO通知，但不太可能需要我们这样做。如果需要取消某项操作，则只需要调用现有的`cancel`方法即可。同样，很少需要修改操作对象中的队列优先级信息。最后，除非操作对象能够动态更改其并发状态，否则不需要为`isConcurrent`键路径提供KVO通知。

与键-值观察（KVO）有关的更多信息以及如何在自定义对象中支持它的更多信息，请参看[Key-Value Observing Programming Guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html#//apple_ref/doc/uid/10000177i)。

## 定制操作对象的执行行为

操作对象的配置在创建它们之后但在将它们添加到队列之前发生。本节中描述的配置类型可以应用于所有操作对象，无论是使用自定义`NSOperation`对象还是使用现有的`NSOperation`子类。

### 配置操作之间的依赖关系

依赖关系是一种序列化不同操作对象的执行的方式。依赖于其他操作的操作无法开始执行，直到它所依赖的所有操作都已完成执行。因此，可以使用依赖关系来在两个操作对象之间创建简单的一对一依赖关系或构建复杂的对象依赖关系图。

要建立两个操作对象之间的依赖关系，可以使用`NSOperation`对象的`addDependency:`方法。此方法创建从当前操作对象到作为参数指定的目标操作对象的**单向**依赖关系。这种依赖意味着当前对象不能执行，直到目标操作对象完成执行。依赖关系也不限于同一队列中的操作。操作对象管理它们自己的依赖关系，因此在操作之间创建依赖关系并将它们全部添加到不同的队列是完全可以接受的。然而，有一件不可接受的事情是在操作之间创建循环依赖关系。

当一个操作的所有依赖都已经完成时，操作对象通常会准备好执行。（如果自定义`isReady`方法的行为，则操作的准备就会根据我们设置的条件来确定。）如果操作对象位于队列中，则队列可以随时开始执行该操作。如果打算手动执行操作，则由我们自己来调用操作对象的`start`方法。

> **重要**：应始终在执行操作或将它们添加到操作队列之前配置依赖关系，之后添加的依赖项可能无法阻止给定的操作对象的执行。

依赖关系依赖于在对象的状态发生改变时每个操作对象发送适当的KVO通知。如果要自定义操作对象的行为，则可能需要在自定义代码中生成对应的KVO通知，以避免导致依赖关系出现问题。

### 更改一个操作的执行优先级

对于已经添加到队列中的操作，执行顺序首先取决于排队的操作是否准备就绪，然后才取决于相对优先级。是否准备就绪取决于操作对其他操作的依赖性，但优先级是操作对象本身的属性。默认情况下，所有新操作对象都具有“正常”优先级，但可以通过调用操作对象的`setQueuePriority:`方法来根据需要提高或降低该优先级。

**优先级仅适用于在同一操作队列中的操作。** 如果应用程序具有多个操作队列，则每个操作队列都独立于其他队列而优先执行自己的操作。因此，低优先级操作仍然可能在不同队列中的高优先级操作之间执行。

优先级并不是依赖关系的替代。优先级决定操作队列开始执行其当前准备就绪的操作的顺序。例如，如果队列中既包含高优先级操作又包含低优先级操作，并且这两个操作都已准备就绪，则队列首先执行高优先级操作。但是，如果高优先级操作未准备就绪，但低优先级操作已准备就绪，则队列首先执行低优先级操作。如果要防止一个操作启动，直到另一个操作完成，则必须使用依赖关系。

### 更改底层线程优先级

在OS X v10.6及更高版本中，可以配置一个操作的底层线程的执行优先级。系统中的线程策略由内核管理，但通常优先级较高的线程比低优先级的线程有更多的运行机会。在操作对象中，可以将线程优先级指定为**0.0**到**1.0**范围的浮点值，其中0.0是最低优先级，1.0是最高优先级。如果没有指定明确的线程优先级，则该操作对象的默认线程优先级为0.5。

要设置操作对象的线程优先级，必须在将操作对象添加到队列（或手动执行）之前调用其`setThreadPriority:`方法。当需要执行操作时，默认的`start`方法会使用指定的值来修改当前线程的优先级。这个新的优先级仅在操作对象的`main`方法执行期间有效。所有其他代码（包括操作的完成block）都以默认的线程优先级运行。如果创建并发操作，并因此重写`start`方法，则必须自己配置线程优先级。

### 配置完成Block

在OS X v10.6及更高版本中，当主任务完成时，操作对象能够执行完成block。可以使用完成block来执行任何我们认为不是主要任务的工作。例如，可以使用完成block通知感兴趣的客户端操作本身已完成。并发操作对象可能会使用此block来生成其最终的KVO通知。

要设置完成block，请使用`NSOperation`对象的`setCompletionBlock:`方法，我们传递给此方法的block应该没有参数并且没有返回值。

## 实现操作对象的一些提示

虽然操作对象很容易实现，但在编写代码时应注意以下几点。以下部分描述了在为操作对象编写代码时应考虑的因素。

### 管理操作对象中的内存

以下部分描述操作对象中良好内存管理的关键因素。有关Objective-C程序内存关联的信息，请参看[Advanced Memory Management Programming Guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/MemoryMgmt.html#//apple_ref/doc/uid/10000011i)。

#### 避免Per-Thread存储

尽管大多数操作在一个线程上执行，但在非并发操作的情况下，该线程通常由操作队列提供。如果操作队列为我们提供线程，则应将该线程视为由队列拥有并且不会被操作触及。具体而言，不应该将任何数据与不是由我们自己提供或管理的线程关联。由操作队列管理的线程根据系统和应用程序的需要来来去去。因此，在使用Pre-Thread存储的操作之间传递数据是不可靠的，并且可能会失败。

对于操作对象，在任何情况下都不应该使用Pre-Thread存储。初始化操作对象时，应该为操作对象提供执行其工作所需的所有内容。因此，操作对象本身提供了所需的上下文存储。所有传入和传出的数据都应该存储在那里，直到它可以集成到应用程序中或者不再需要。

#### 根据需要保留对操作对象的引用

不能因为操作对象异步运行，就在创建它们之后将它们完全忘记。它们仍然只是对象，并且由我们自己来管理代码所需的任何对它们的引用。如果需要在操作完成后从操作中检索结果数据，这一点尤其重要。

应该始终保留对操作对象的引用的原因是我们可能没有机会在稍后向队列请求操作对象。队列尽可能快地调度和执行操作。在很多情况下，操作对象被添加到队列后，队列会立即开始执行操作。当我们自己的代码返回到队列以获取对该操作的引用时，该操作可能已经完成并从队列中移除。

### 错误和异常处理

由于操作本质上是应用程序内的离散实体，因此它们负责处理出现的任何错误或者异常。在OS X v10.6及更高版本中，`NSOperation`类提供的默认`start`方法不会捕获异常。（在OS X v10.5中，`start`方法确实会捕获并抑制异常。）我们自己的代码应该始终直接捕获并抑制异常。它还应该检查错误代码并根据需要通知应用程序的相应部分。如果我们重写了`start`方法，必须类似地捕获自定义实现中的任何异常，以防止它们离开底层线程的范围。

应该准备处理的错误情况类型包括以下几种：
- 检查并处理UNIX errno-style错误代码。
- 检查方法和函数返回的显示错误代码。
- 捕获我们自己的代码或其他系统框架抛出的异常。
- 捕获`NSOperation`类自身抛出的异常，发送以下情况时会抛出异常：
    - 当操作未准备好执行但是调用其`start`方法时。
    - 当操作正在执行或完成执行（可能是因为它已被取消）并且其`start`方法再次被调用。
    - 当尝试将完成block添加到正在执行或已完成的操作时。
    - 当尝试检索已取消的`NSInvocationOperation`对象的结果时。

如果我们的自定义代码确实遇到异常或错误，应该采取任何必要的步骤将错误传播到应用程序的其余部分。`NSOperation`类不提供将错误结果码或异常传递给应用程序其他部分的显式方法。因此，如果这些信息对应用程序很重要，我们必须提供必要的代码。

## 确定操作对象的适用范围

尽管能够向操作队列中添加任意大量的操作，但这样做通常是不切实际的。和任何对象一样，`NSOperation`类的实例消耗内存并且还带来与其执行相关的实际成本。如果每个操作对象执行少量工作，并且创建了数以万计的操作对象，那么我们可能会发现调度操作比开展实际工作会花费更多时间。如果应用程序的内存已经受到内存限制，我们可能会发现在内存中有数以万计的操作对象会进一步降低性能。

有效使用操作的关键是在我们需要做的工作量和保持计算机繁忙之间找到适当的平衡点。尽量确保操作对象执行合理的工作量。例如，如果应用程序创建100个操作对象来在100个不同的值上执行相同的任务，请考虑创建10个操作对象，以便每个操作处理10个值。

还应该避免同时向队列中添加大量操作，或者避免不断将操作对象添加到队列中，而不是将其快速处理。当我们有很多工作要做时，想要让队列中有足够多的操作以便让计算机保持忙碌状态，但是又不希望一次创建那么多操作而导致应用程序内存不足，则应当批量创建操作对象，而不是用操作对象淹没队列。当一个批处理完成执行时，使用完成block告知应用程序创建一个新的批处理。

当然，我们创建的操作对象的数量以及在每个操作中执行的工作量是可变的，并且完全取决于应用程序。应该始终使用诸如Instruments之类的工具来帮助我们在效率和速度之间找到适当的平衡点。有关Instruments以及其他性能工具的概述，请参看[Performance Overview](https://developer.apple.com/library/content/documentation/Performance/Conceptual/PerformanceOverview/Introduction/Introduction.html#//apple_ref/doc/uid/TP40001410)。

## 执行操作

### 将操作添加到操作队列

到目前为止，执行操作的最简单方法是使用操作队列，该操作队列是`NSOperationQueue`类的一个实例。应用程序负责创建和维护它打算使用的任何操作队列。应用程序可以有任意数量的队列，但是在给定的时间点可以执行的操作数量有实际限制。操作队列与系统一起工作来将并发操作数量限制为适合可用内核和系统负载的值。因此，创建额外的队列并不意味着可以执行其他操作。

以下代码展示了如何创建一个队列：
```
NSOperationQueue* aQueue = [[NSOperationQueue alloc] init];
```
要将操作添加到队列中，请使用`addOperation:`方法。在OS X v10.6及更高版本中，可以使用`addOperations:waitUntilFinished:`方法添加操作组，也可以使用`addOperationWithBlock:`方法将block对象直接添加到队列（没有相应的操作对象）。这些方法中的每一个都将一个操作（或多个操作）排队，并通知队列应该开始处理它们。在大多数情况下，操作在被添加到队列后不久就会被立即执行，但操作队列可能由于以下几种原因而延迟排队操作的执行。特别是，如果排队的操作依赖于尚未完成的其他操作，则执行可能会延迟。如果操作队列本身暂停或正在执行的操作数量为其最大并发操作数，则执行也可能会延迟。以下示例显示了将操作添加到队列的基本语法：
```
[aQueue addOperation:anOp]; // Add a single operation
[aQueue addOperations:anArrayOfOps waitUntilFinished:NO]; // Add multiple operations
[aQueue addOperationWithBlock:^{
    /* Do something. */
}];
```
> **重要**：应该在将操作对象添加到队列中之前对操作对象进行所有必要的配置和修改，因为一旦添加操作对象，该操作可能立即执行，这对于更改后的预期效果来说可能太迟了。

尽管`NSOperationQueue`类是为并发执行操作而设计的，但可以强制一个队列一次仅执行一个操作。`setMaxConcurrentOperationCount:`方法运行我们为操作队列对象配置最大并发操作数量。将值`1`传递给此方法会使队列一次只执行一个操作。尽管一次只能执行一个操作，但执行顺序仍然基于其他因素，例如每个操作是否准备就绪及其分配的优先级。因此，串行操作队列并不能提供与Grand Central Dispatch中的串行调度队列完全相同的行为。如果操作对象的执行顺序对我们非常重要，那么在将操作添加到队列之前，应该使用依赖关系来建立该顺序。有关配置依赖关系的信息，请参看[配置操作之间的依赖关系](jump)。

有关使用操作队列的信息，请参看[NSOperationQueue Class Reference](https://developer.apple.com/documentation/foundation/nsoperationqueue)。

### 手动执行操作

虽然操作队列是执行操作对象最方便的方式，但也可以在没有队列的情况下执行操作。但是，如果选择手动执行操作，则应该在代码中采取一些预防措施。特别是，该操作必须已经准备好执行，并且必须始终使用其`start`方法启动它。

在操作对象的`isReady`方法返回`YES`之前，操作对象不能被执行。`isReady`方法被集成到`NSOperation`类的依赖管理系统中，以提供操作对象的依赖关系的状态。只有当其依赖关系被清除时，才可以开始执行。

手动执行操作时，应该始终使用`start`方法来开始执行。使用该方法而不是`main`方法或者其他方法的原因是因为`start`方法在实际运行自定义代码之前会执行多个安全检查。特别是，默认的`start`方法会生成操作对象正确处理其依赖关系所需的KVO通知。该方法还可以正确避免执行操作（如果它已被取消）和在操作实际上未准备就绪时执行而引发异常。

如果应用程序定义了并发操作对象，那么在启动它们之前，还应该考虑调用操作对象的`isConcurrent`方法。在此方法返回`NO`的情况下，我们的自定义代码可以决定是在当前线程中同步执行操作还是创建一个单独的线程。

以下代码显示了在手动执行操作之前应该执行的检查的简单示例。如果方法返回`NO`，则可以安排定时器在稍后再次调用该方法。然后，保持定时器重新定时，直到方法返回为`YES`（这可能是因为操作被取消而造成的）。
```
- (BOOL)performOperation:(NSOperation*)anOp
{
    BOOL        ranIt = NO;

    if ([anOp isReady] && ![anOp isCancelled])
    {
        if (![anOp isConcurrent])
            [anOp start];
        else
            [NSThread detachNewThreadSelector:@selector(start) toTarget:anOp withObject:nil];
            
        ranIt = YES;
    }
    else if ([anOp isCancelled])
    {
        // If it was canceled before it was started,
        //  move the operation to the finished state.
        [self willChangeValueForKey:@"isFinished"];
        [self willChangeValueForKey:@"isExecuting"];
        executing = NO;
        finished = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];

        // Set ranIt to YES to prevent the operation from
        // being passed to this method again in the future.
        ranIt = YES;
    }
    return ranIt;
}
```

### 取消操作

一旦操作对象被添加到操作队列中，操作对象实际上由队列拥有并且不能被删除。从操作队列中取出操作的的唯一方法是取消它。可以通过调用单个操作对象的`cancel`方法来取消它，也可以通过调用操作队列对象的`cancelAllOperations`方法来取消队列中的所有操作对象。

只有在确定不再需要时才应取消操作。发出取消命令会将操作对象置于“取消”状态，从而阻止其执行。由于取消的操作仍被视为“已完成”，因此依赖于它的操作对象将收到对应的KVO通知以清除该依赖关系。因此，取消所有排队操作来响应某些重大事件（如应用程序退出或用户特别请求取消）比选择性取消操作更为常见。

### 等待操作完成

为了获得最佳性能，应该将操作设计为尽可能异步，使应用程序在执行操作时可以自由地执行额外的工作。如果创建操作对象的代码也处理该操作对象的结果，则可以使用`NSOperation`的`waitUntilFinished`方法来阻拦该代码直到操作完成。但是，一般来说最好避免使用该方法。阻塞当前线程可能是一个方便的解决方案，但它确实会在您的代码中引入更多序列并限制并发执行的操作数量。

> **重要说明**：永远不要等待应用程序主线程中的操作。应该仅在辅助线程或其他操作中这样做。阻塞主线程会导致应用程序无法响应用户事件，并可能导致应用程序显示无响应。

除了等待单个操作完成外，还可以通过调用`NSOperationQueue`的`waitUntilAllOperationsAreFinished`方法来等待队列中的所有操作。当等待整个队列完成时，请注意应用程序的其他线程仍可以将操作添加到队列中，从而延长等待时间。

### 暂停和恢复队列

如果想要暂时停止执行操作，则可以使用`setSuspended:`方法挂起响应的操作队列。暂停队列不会导致已执行的操作在其任务执行期间暂停。它只是阻止新的操作被安排执行。我们可能会暂停队列以响应用户请求暂停任何正在进行的工作，因为期望用户可能最终想要恢复该工作。

# iOS并发编程 -- Dispatch Queues

Grend Central Dispatch（GCD）调度队列是执行任务的强大工具。调度队列让我们可以与调用者异步或同步地执行任何代码块。可以使用调度队列来执行几乎所有用于在单独的线程上执行的任务。调度队列的优点是它们相应的线程代码更简单有效地执行这些任务。

本文提供了有关调度队列的介绍，以及有关如何使用它们在应用程序中执行常规任务的信息。如果想用调度队列替换现有的线程代码，可以从[Migrating Away from Threads](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/ThreadMigration/ThreadMigration.html#//apple_ref/doc/uid/TP40008091-CH105-SW1)中找到有关如何执行此操作的一些其他提示。

## 关于调度队列

调度队列是一种在应用程序中异步并行执行任务的简单方法。任务只是应用程序需要执行的一些工作。例如，可以定义一个任务来执行一些计算，创建或修改数据结构，处理从文件读取的某些数据或任何数量的事物。通过将相应的代码放入函数或block对象中并将其添加到调度队列来定义任务。

调度队列是一个类似于对象的结构，其用于管理向其提交的任务。所有的调度队列都是**先进先出**的数据结构。因此，添加到队列中的任务始终以与其被添加到队列的顺序来启动。GCD自动为我们提供了一些调度队列，但我们可以为特定目的创建其他调度队列。下表列出了可用于应用程序的调度队列的类型以及如何使用它们。

| Type | Description |
|-------|---------------|
| Serial | 串行队列（也称为私有调度队列）按照任务被添加到队列中顺序每次执行一个任务。当前正在执行的任务运行在由调度队列管理的不同线程上（可能因任务而异）。串行队列通常用于同步对特定资源的访问。<br>可以根据需要创建尽可能多的串行队列，并且每个队列都可以与其他队列同时运行。换句话说，如果创建了四个串行队列，每个队列只执行一个任务，但最多可以同时执行四个任务，每个队列一个。 |
| Concurrent | 并行队列（也称为全局调度队列）同时执行一个或多个任务，但任务仍按其添加到队列中的顺序启动。当前正在执行的任务在由调度队列管理的不同线程上运行。在任何给定点执行的任务的确切数量是可变的，并取决于系统条件。<br>在iOS 5及更高版本中，可以在自己创建调度队列时将队列类型指定为`DISPATCH_QUEUE_CONCURRENT`。另外，还有四个预定义的全局并发队列供应用程序使用。 |
| Main dispatch queue | 主调度队列是一个全局可用的串行队列，用于执行应用程序主线程上的任务。该队列与应用程序的 run loop（如果存在的话）一起工作，以将排队中的任务的执行与附加到 run loop 中的其他事件源的执行错开。因为它运行在应用程序的主线程上，所以主队列通常用作应用程序的关键同步点。 |

当向应用程序添加并发时，调度队列相对于线程提供了几个优点。最直接的优点是工作队列编程模型的简单性。使用线程，必须为要执行的工作以及创建和管理线程本身编写代码。调度队列让我们专注于我们实际想要执行的工作，而无需担心线程创建和管理。相反，系统会为我们处理所有的线程创建和管理。优点是系统能够比任何单个应用程序更有效地管理线程。系统可以根据可用资源和当前系统条件动态扩展线程数量。另外，相比我们自己创建线程，系统通常能够更快地开始运行任务。

为调度队列编写代码通常比为线程编写代码更容易，编写代码的关键是设计独立并且能够异步运行的任务。（这对于线程和调度队列都是如此。）但是调度队列具有优势的地方在于可预测性。如果有两个访问相同共享资源但在不同线程上运行的任务，则任一线程都可以先修改资源，并且需要使用锁来确保两个任务不会同时修改该资源。使用调度队列，可以将两个任务添加到串行调度队列，以确保在任何给定时间只有一个任务修改了资源。这种基于队列的同步比锁更有效，因为在有竞争和无竞争的情况下，锁始终需要昂贵的内核陷阱，而调度队列主要在应用程序的进程空间中工作，并且只在绝对有必要时调用内核。

虽然在串行队列中执行的任务不能同时执行，但必须记住，如果两个线程同时锁定，那么线程提供的任何并发会丢失或者显著减少。更重要的是，线程模型需要创建两个线程，它们同时占用内核和用户空间内存。调度队列不会为它们的线程支付相同的内存损失，并且它们使用的线程保持繁忙并且不会被阻塞。

有关调度队列的其他一些关键要点包括以下内容：
- 调度队列相对于其他调度队列并行执行其任务。任务的序列化仅限于单个调度队列中的任务。
- 系统确定任何时间点执行的任务总数。因此，有100个不同队列且每个队列有100个任务的应用程序可能不会并行执行所有这些任务（除非它具有100个或更多有效内核）。
- 在选择启动哪些新任务时，系统会考虑队列优先级。
- 队列中的任务在添加到队列时必须已准备好执行。（与Cocoa操作对象的使用不同）
- 私有调度队列是被引用计数的对象。除了在自己的代码中保留队列之外，请注意，调度源也可以附加到队列中，并增加其引用计数。因此，必须确保所有调度源都被取消，并且所有`retain`调用均通过对应的`release`调用来保持平衡。有关引用和释放调度队列的更多信息，请参看[调度队列的内存管理](jump)。有关调度源的更多信息，请参看[iOS并发编程 -- Dispatch Sources](jump)。

## 与队列相关的技术

除了调度队列之外，Grand Central Dispatch还提供了几种使用队列来帮助管理代码的技术。下表列出了这些技术。
| Technology  | Description |
|---------------|---------------|
| Dispatch groups | 调度组是一种监听一组block对象是否已完成执行的方法。（可以根据需要同步或异步监听block）组为代码提供有效的同步机制，这取决于其他任务的完成情况。 |
| Dispatch semaphores | 调度信号与传统信号相似，但通常更加高效。只有当调用线程因为信号量不可用而需要被阻塞时，调度信号才会调用内核。如果信号量可用，则不会调用内核。 |
| Dispatch sources | 调度源生成通知来响应特定类型的系统事件。可以使用调度源来监听事件，例如进程通知，信号和描述符事件等。发送事件时，调度源将任务代码异步提交给调度队列进行处理。 |

## 创建和管理调度队列

在将任务添加到队列之前，必须确定要使用的队列类型以及打算如何使用它。调度队列可以串行或者并行执行任务。另外，如果有针对队列的特定用途，则可以相应地配置队列属性。以下各节介绍如何创建并配置调度队列以供使用。

### 获取全局并发调度队列

当有多个可以并行运行的任务时，并发调度队列非常有用。并发调度队列仍然是一个先进先出的队列，但是并发队列可能会在任何先加入的任务完成执行之前就执行后添加的任务。并发队列在任何给定时刻执行的实际任务数量都是可变的，并且可以随应用程序中的条件更改而动态更改。许多因素会影响并发队列执行的任务数量，包括可用内核数量，其他进程执行的工作量以及其他串行调度队列中的任务数量和优先级。

系统为每个应用程序提供四个并发调度队列。这些队列对于应用程序来说是全局的，并且仅通过它们的优先级来区分。因为它们是全局性的，所以不用明确地创建它们。而是使用`dispatch_get_global_queue`函数请求其中一个队列，如下所示：
```
dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
```
除了获取默认的并发队列之外，还可以通过将`DISPATCH_QUEUE_PRIORITY_HIGH`和`DISPATCH_QUEUE_PRIORITY_LOW`常量传递给函数来获得高优先级和低优先级的队列，或者通过传递`DISPATCH_QUEUE_PRIORITY_BACKGROUND`常量来获取后台队列。高优先级并发队列中的任务会在默认和低优先级队列中的任务之前执行，默认队列中的任务会在低优先级队列中的任务之前执行。

> **注意**：`dispatch_get_global_queue`函数的第二个参数保留给将来扩展。现在，应该总是为这个参数传递0。

**虽然调度队列是被引用计数的对象，但我们不需要对全局并发队列执行`retain`和`release`操作。因为它们对应用程序是全局的，所以对这些队列执行`retain`和`release`操作将被忽略。** 因此，我们不需要存储对这些队列的引用，只需要在需要用的时候调用`dispatch_get_global_queue`函数来获取就行。

### 创建串行调度队列

当希望任务按特定顺序执行时，串行队列是非常有用的。串行队列一次只执行一个任务，并且始终从队列的头部抽取任务。可以使用串行队列而不是锁来保护共享资源或可变数据结构。与锁不同，串行队列确保任务按可预测的顺序执行。只要将任务异步提交到串行队列，队列就永远不会死锁。

与并发队列不同，必须明确创建并管理需要使用的任何串行队列。可以为应用程序创建任意数量的串行队列，但应该避免单独创建大量的串行队列，以便尽可能多地并行执行任务。如果想要并行执行大量任务，请将它们提交到某个全局并发队列。创建串行队列时，尝试确定每个队列的用途，例如保护资源或同步应用程序的某些关键行为。

以下代码显示了创建自定义串行队列所需的步骤。`dispatch_queue_create`函数有两个参数：队列名称和队列属性集合。调试器和性能工具显示队列名称，以帮助我们跟踪我们的任务如何执行。队列属性保留供将来使用，现在应传递`NULL`。
```
dispatch_queue_t queue;
queue = dispatch_queue_create("com.example.MyQueue", NULL);
```
除了创建的任何自定义队列之外，系统还会自动创建一个串行队列并将其绑定到应用程序的主线程。有关获取主线程队列的更多信息，请参看[在运行时获取通用队列](jump)。

### 在运行时获取通用队列

Grand Central Dispatch提供的功能允许我们从应用程序访问几个常见的调度队列：
- 使用`dispatch_get_current_queue`函数进行调试或测试当前队列的标识。在block对象中调用该函数，该函数将返回block被提交到的队列（现在正在运行该队列）。在block外部调用此函数将返回应用程序的默认并发队列。
- 使用`dispatch_get_main_queue`函数获取与应用程序主线程相关联的串行调度队列。此队列是为Cocoa应用程序以及调用`dispatch_main`函数或者在主线程上配置run loop（使用`CFRunLoopRef`类型或者`NSRunLoop`对象）的应用程序自动创建的。
- 使用`dispatch_get_global_queue`函数来获取任何共享全局并发队列。

### 调度队列的内存管理

调度队列和其他调度对象是被引用计数的数据类型。创建串行调度队列时，其初始引用计数为1，可以使用`dispatch_retain`和`dispatch_release`函数根据需要递增和递减引用计数。当队列的引用计数为零时，系统会异步释放队列。

保留和释放调度对象（如队列）以确保它们在使用时还保留在内存中很重要。与Cocoa对象的内存管理一样，一般规则是，如果打算使用我们创建的队列，则应在使用该队列之前保留该队列，并在不需要时释放它。这种基本模式可以确保只要使用队列，队列就会保留在内存中。

即使我们实现了一个垃圾回收应用程序，仍然必须保留并释放我们创建的调度队列和其他调度对象。Grand Central Dispatch不支持用于回收内存的垃圾回收模型。

### 使用队列存储自定义上下文信息

所有调度对象（包括调度队列）都允许我们将自定义上下文数据与对象相关联。要在给定的对象上设置和获取这些数据，可以使用`dispatch_set_context`和`dispatch_get_context`函数。系统不会以任何方式使用我们的自定义数据，并且由我们自己在适当的时间分配和销毁数据。

对于队列，我们可以使用上下文数据来存储指向Objective-C对象或其他数据结构的指针来帮助标识队列或者我们代码的预期用法。可以使用队列的`finalizer`函数（该函数已废弃）在队列被销毁之前销毁上下文数据。以下代码显示了如何编写一个清除队列的上下文数据的终结器函数的示例。
```
void myFinalizerFunction(void *context)
{
    MyDataContext* theData = (MyDataContext*)context;

    // Clean up the contents of the structure
    myCleanUpDataContextFunction(theData);

    // Now release the structure itself.
    free(theData);
}

dispatch_queue_t createMyQueue()
{
    MyDataContext*  data = (MyDataContext*) malloc(sizeof(MyDataContext));
    myInitializeDataContextFunction(data);

    // Create the queue and set the context data.
    dispatch_queue_t serialQueue = dispatch_queue_create("com.example.CriticalTaskQueue", NULL);
    dispatch_set_context(serialQueue, data);
    dispatch_set_finalizer_f(serialQueue, &myFinalizerFunction);

    return serialQueue;
}
```

## 将任务添加到队列

要执行一个任务，必须将其调度到合适的调度队列。可以同步或异步调度任务，并且可以单独或成组地调度它们。任务一旦进入队列，队列将负责尽快执行这些任务，为这些任务和已在队列中的任务添加约束。本节将介绍将任务调度到队列中的一些技术，并介绍每种技术的优点。

### 将单个任务添加到队列

有两种方法可以将任务添加到队列：同步或者异步。如果可能，使用`dispatch_async`和`dispatch_async_f`函数的异步执行要优于同步。当我们将一个block对象或函数添加到队列中时，是无法得知该代码何时执行的。因此，通过异步添加block或者函数，可以调度代码的执行并继续从调用线程执行其他工作。如果我们正在应用程序的主线程安排任务（这可能是为了响应某些用户事件），这一点尤其重要。

尽管应尽可能异步添加任务，但可能有时候仍然需要同步添加任务以防止竞争状况或者其他同步错误。在这些情况下，可以使用`dispatch_sync`和`dispatch_sync_f`函数将任务添加到队列中。这些函数会阻塞当前的执行线程，直到指定的任务完成执行。

> **重要**：永远不要在和传递给`dispatch_sync`和`dispatch_sync_f`函数的队列相同的队列中的正在执行的任务中调用`dispatch_sync`和`dispatch_sync_f`函数。这对串行队列尤其重要，因为这样做会导致死锁，对于并发队列也要避免这样做。

以下代码显示了如何基于block来异步和同步调度任务：
```
dispatch_queue_t myCustomQueue;
myCustomQueue = dispatch_queue_create("com.example.MyCustomQueue", NULL);

dispatch_async(myCustomQueue, ^{
    printf("Do some work here.\n");
});

printf("The first block may or may not have run.\n");

dispatch_sync(myCustomQueue, ^{
    printf("Do some more work here.\n");
});
printf("Both blocks have completed.\n");
```

### 任务完成后执行Completion Block

就其本质而言，调度到队列中的任务独立于创建它们的代码运行。但是，当任务完成后，应用程序可能仍然需要通知该事实，以便它可以合并结果。使用传统的编程，可以使用回调机制来这样做，但对于调度队列，可以使用completion block。

completion block只是在原始任务结束时调度给队列的另一段代码。调用代码通常在其启动任务时提供completion block作为参数。所有任务代码所要做的就是在指定的队列完成其工作时，将指定的block或函数提交给指定的队列。

以下代码展示了使用block实现的计算平均数的函数。计算平均数函数的最后两个参数允许调用者报告结果时指定一个队列和block。计算平均数函数在计算出结构后，将结果传递给指定的block并将其调度到队列中。为了防止队列被过早释放，首先保留该队列并在completion block被调度后释放它是至关重要的。
```
void average_async(int *data, size_t len,
dispatch_queue_t queue, void (^block)(int))
{
    // Retain the queue provided by the user to make
    // sure it does not disappear before the completion
    // block can be called.
    dispatch_retain(queue);

    // Do the work on the default concurrent queue and then
    // call the user-provided block with the results.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int avg = average(data, len);
        dispatch_async(queue, ^{ block(avg);});

        // Release the user-provided queue when done
        dispatch_release(queue);
    });
}
```

### 并行执行循环迭代

在循环执行固定迭代次数的地方，使用并发调度队列可能会提高性能。例如，假设有一个for循环，通过每个循环迭代完成一些工作：
```
for (i = 0; i < count; i++) {
    printf("%u\n",i);
}
```
如果在每次迭代执行期间执行的工作与所有其他迭代期间执行的工作不同，并且每个后续循环完成的顺序不重要，则可以使用`dispatch_apply`或者`dispatch_apply_f`函数调用来替代循环。这些函数为每个循环迭代提交指定的block或函数到一个队列中。当调度到并发队列时，可以并行执行多个循环迭代。

调用`dispatch_apply`或者`dispatch_apply_f`函数时可以指定一个串行队列或一个并行队列。传入并行队列允许我们同时执行多个循环迭代，并且是使用这些函数的最常见方式。虽然也允许使用串行队列，但这相对于使用循环并没有真正的性能优势。

> **重要**：与常规for循环一个，`dispatch_apply`或者`dispatch_apply_f`函数在所有循环迭代完成之后才会返回。因此，在从正在队列的上下文中执行的代码中调用它们时要小心。如果作为参数传递给函数的队列是串行队列，并且与执行当前代码的队列相同，则调用这些函数将导致队列死锁。因为它们会阻塞当前线程，使事件处理循环无法及时响应事件，所以在主线程调用这些函数时应该小心。如果循环代码需要大量的处理时间，则可能需要从不同的线程调用这些函数。

以下代码显示了如何使用`dispatch_apply`函数替代前面的for循环。传递给`dispatch_apply`函数的block必须包含一个标识当前循环迭代的参数。在执行该block时，此参数的值在第一次迭代中为0，在第二次中为1，依此类推。最后一次迭代的参数值时count-1，其中count时迭代的总次数。
```
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

dispatch_apply(count, queue, ^(size_t i) {
    printf("%u\n",i);
});
```
应该确保任务代码在每次迭代中都会做一些合理的工作。与任何调度到队列的block或函数一样，调度该代码以供执行也会有开销。如果循环的每次迭代执行少量工作，则调度代码的开销可能会超过将其调度到队列中可能带来的性能提升。如果在测试过程中发现这是真的，则可以使用跨越来增加每次循环迭代期间执行的工作量。通过跨越，可以将原始循环的多个迭代组合到一个block中，并按比例减少迭代次数。例如，如果最初执行100次迭代，但决定使用4次跨越，则现在在每个block中执行4次循环迭代，并且迭代次数变为25次。有关如何实现跨越的示例，请参看[改进循环代码](jump)。

### 在主线程中执行任务

Grand Central Dispatch提供了一个特殊的调度队列，可以使用它来在应用程序的主线程上执行任务。该队列为所有应用程序自动提供，并由在主线程上设置了run loop（由CFRunLoopRef类型或NSRunLoop对象管理）的应用程序自动排空。如果没有创建Cocoa应用程序，也不想显式设置run loop，则必须调用`dispatch_main`函数来显式排空主调度队列。虽然仍然可以将任务添加到队列中，但如果不调用此函数，这些任务就永远不会执行。

可以通过调用`dispatch_get_main_queue`函数来获取应用程序主线程的调度队列。添加到该队列的任务在主线程中串行执行。因此，可以将此队列用作同步点，以便在应用程序的其他部分完成工作。

### 在任务中使用Objective-C对象

GCD为Cocoa内存管理技术提供了内置支持，因此可以在提交到调度队列的block中自由使用Objective-C对象。每个调度队列维护自己的自动释放池，以确保自动释放分对象在某个时刻被释放。**队列无法保证在何时实际释放这些对象。**

如果应用程序的内存受限并且block创建了多个自动释放对象，则创建我们自己的自动释放池是确保及时释放对象的唯一方法。如果block创建了数百个对象，则可能需要创建多个自动释放池或者定期排空自动释放池。

有关自动释放池和Objective-C内存管理的更多信息，请参看[Advanced Memory Management Programming Guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/MemoryMgmt.html#//apple_ref/doc/uid/10000011i)。

## 暂停和恢复队列

可以通过挂起队列暂时阻止其执行block对象。使用`dispatch_suspend`函数暂停调度队列，并使用`dispatch_resume`函数恢复它。调用`dispatch_suspend`函数会使队列的暂停引用计数加1，调用`dispatch_resume`会使队列的暂停引用计数减1。当暂停引用计数大于零时，队列保持挂起状态。因此必须保持`dispatch_suspend`函数的调用与`dispatch_resume`函数的调用平衡，以便恢复处理block。

> **重要提示**：暂停和恢复的调用式异步的，暂停队列不会导致正在执行的block停止执行。

## 使用调度信号来调节有限资源的使用

如果提交给调度队列的任务访问某些有限的资源，则可能需要使用调度信号来调节同时访问该资源的任务数量。调度信号像常规信号一样工作，只有一个例外。当资源可用时，获取调度信号比获取传统信号需要的时间更少。这是因为Grand Central Dispatch不会为这种特定情况去调用内核。只有在资源不可用并且系统需要停止线程直到发出信号为止时，才会调用系统内核。

使用调度信号的语义如下：
- 当创建信号量时（使用`dispatch_semaphore_create`函数），可以指定一个指示可用资源数量的正整数。
- 在每个任务中，调用`dispatch_semaphore_wait`函数来等待信号。
- `dispatch_semaphore_wait`函数调用返回时，获取资源并完成要执行的工作。
- 当完成工作后，释放资源并调用`dispatch_semaphore_signal`函数发出信号。

有关这些步骤如何工作的示例，请考虑使用系统中的描述文件符。每个应用程序都使用有限数量的文件描述符。如果我们有一个处理大量文件的任务，我们不希望一次打开太多的文件以至于用光文件描述符。相反，我们可以使用信号量来限制文件处理代码一次使用的文件描述符的数量。如下所示：
```
// Create the semaphore, specifying the initial pool size
dispatch_semaphore_t fd_sema = dispatch_semaphore_create(getdtablesize() / 2);

// Wait for a free file descriptor
dispatch_semaphore_wait(fd_sema, DISPATCH_TIME_FOREVER);
fd = open("/etc/services", O_RDONLY);

// Release the file descriptor when done
close(fd);
dispatch_semaphore_signal(fd_sema);
```
在创建信号量时，可以指定可用资源的数量。该值将成为信号量的初始计数变量。每次在信号量上等待时，`dispatch_semaphore_wait`函数会将该变量的计数减1.如果结果值为负数，该函数会通知内核阻塞当前线程。另一方面，`dispatch_semaphore_signal`函数将计数变量加1，表示资源已被释放。如果有任务被阻塞并等待资源，它们中的一个随后会被解除阻塞并允许其工作。

## 等待排队任务组

调度组是阻塞线程直到一个或多个任务完成执行的一种方式。例如，在调度几个任务来计算一些数据之后，可以使用一个组来等待这些任务，然后在它们都完成时处理结果。另一种使用调度组的方式是作为线程连接的替代方法。可以将相应的任务添加到一个调度组然后等待整个组，而不是启动多个子线程并将每个任务加入其中一个线程。

以下代码显示了设置一个组并调度任务给它，然后等待结果的基本过程。不是使用`dispatch_async`函数将任务调度到队列，而是使用`dispatch_group_async`函数将任务与组相关联并队列执行。要等待一组任务完成，可以使用`dispatch_group_wait`函数传递相应的组。
```
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_group_t group = dispatch_group_create();

// Add a task to the group
dispatch_group_async(group, queue, ^{
    // Some asynchronous work
});

// Do some other work while the tasks execute.

// When you cannot make any more forward progress,
// wait on the group to block the current thread.
dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

// Release the group when it is no longer needed.
dispatch_release(group);
```

## 调度队列和线程安全

在调度队列中讨论线程安全可能看起来很奇怪，但线程安全仍然是一个相关主题。任何时候在应用程序中实现并发时，都应该知道以下几件事情：
- 调度队列本身是线程安全的。换句话说，我们可以将任务从系统中的任何线程提交到调度队列，而无需首先获取锁或者同步访问队列。
- 不要从传递给`dispatch_sync`函数的同一队列中执行的任务中调用`dispatch_sync`函数。这样做会导致队列死锁。如果需要调度到当前队列，请使用`dispatch_async`函数异步执行。
- 避免从提交给调度队列的任务中获取锁。虽然使用来自任务的锁是安全的，但是当我们获取锁时，如果该锁不可用，则可能会完全阻塞串行队列。同样，对于并发队列，等待锁可能会阻止执行其他任务。如果需要同步部分代码，请使用串行调度队列而不是锁。
- 尽管我们可以获取有关运行任务的基础线程的信息，但最好避免这样做。有关调度队列与线程的兼容性的更多信息，请参看[Compatibility with POSIX Threads](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/ThreadMigration/ThreadMigration.html#//apple_ref/doc/uid/TP40008091-CH105-SW18)。

有关如何将现有线程代码更改为使用调度队列的其他提示，请参看[Migrating Away from Threads](https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/ThreadMigration/ThreadMigration.html#//apple_ref/doc/uid/TP40008091-CH105-SW1)。

# iOS并发编程 -- Dispatch Sources

当我们与底层系统进行交互时，必须为该任务做好准备，以便只花费少量时间。调用内核或其他系统层涉及上下文的变化，与在我们自己的进程中发生的调用相比，这种变化相当昂贵。因此，许多系统库提供异步接口，以允许我们的代码向系统提交请求，并在处理该请求时继续执行其他工作。Grand Central Dispatch通过允许我们提交请求并使用block和调度队列将结果报告回我们的代码来构建此一般行为。

## 关于调度源

调度源是协调特定低级系统事件处理的基本数据类型。Grand Central Dispatch支持以下类型的调度源：
- 定时器调度源生成定期通知。
- 信号调度源在UNIX信号到达时通知我们。
- 描述符源通知我们各种基于文件和基于套接字的操作：例如：
    - 当数据可供读取时。
    - 当可以写入数据时。
    - 在文件系统中删除，移动或重命名文件时。
    - 文件元信息发生变化时。
- 进程调度源通知我们与进程相关的事件，例如：
    - 当一个进程退出时。
    - 当进程发出一个fork或者exec调用类型时。
    - 当一个信号被传递给进程时。
- Mach port调度源通知我们Mach相关的事件。
- 自定义调度源由我们自己定义并触发。

调度源取代了通常用于处理系统相关事件的异步回调函数。配置调度源时，可以指定要监听的事件以及用于处理这些事件的调度队列和代码。可以使用block对象或函数来指定我们的代码。当监听到事件触发时，调度源将block或函数提交给指定的调度队列执行。

与手动提交到队列的任务不同，调度源为应用程序提供连续的事件源。调度源会保留其附加的调度队列，直到我们明确取消调度。附加调度队列后，只要相应的事件发生，调度源就会将相关的任务代码提交给调度队列。某些事件（如定时器事件）会定期发生，但大多数情况下只会在特定条件出现时偶发出现。因此，调度源保留其关联的调度队列，以防止可能仍在等待中的事件过早释放。

为防止事件在调度队列中积压，调度源实现了一个事件合并设计。如果新事件在之前事件的事件处理程序排队和执行之前到达，那么调度源会将新事件数据中的数据与旧事件中的数据合并。根据事件的类型，合并可能会取代旧事件或更新其保存的信息。例如，基于信号的调度源仅提供关于最新信号的信息，但也报告自从最后一次调用事件处理程序以来已传送了多少信号。

## 创建调度源

创建调度源涉及创建事件源和调度源本身。事件源是处理事件所需的本地数据结构。例如，对于基于描述符的调度源，需要打开描述符和一个需要用来获取目标程序的进程ID的基于进程的源。我们可以为我们的事件源创建相应的调度源，如下所示：
1. 使用`dispatch_source_create`函数创建调度源。
2. 配置调度源：
    - 为调度源分配一个事件处理程序。
    - 对于定时器源，使用`dispatch_source_set_timer`函数设置定时器信息。
3. （可选）分配一个取消处理程序给调度源。
4. 调用`dispatch_resume`开始处理事件。

由于调度源在能够使用之前还需要一些额外的配置，`dispatch_source_create`函数会返回处于暂停状态的调度源。在暂停期间，调度源接收事件但是不处理它们。这样就给了我们时间去设置一个事件处理程序并执行处理实际事件所需的任何其他配置。

以下部分展示如何配置调度源的各个方面。有关如何配置具体调度源的类型的详细示例，请参看[调度源示例](jump)。有关用于创建和配置调度源的函数的额外信息，请参看[Grand Central Dispatch (GCD) Reference](jump)。

### 编写和设置事件处理程序

## 调度源示例

### 创建一个定时器

定时器调度源基于时间间隔定期生成事件，可以使用定时器启动需要定期执行的任务。例如，游戏和其他图形密集型应用程序可能会使用定时器来启动屏幕或者动画更新，也可以设置一个定时器并设置结果事件检查经常更新的服务器上的新信息。

所有定时器调度源都是间隔定时器--即一旦创建，它们会在我们指定的时间间隔传递定期事件。当创建一个定时器调度源时，误差值是必须指定的值之一，它能够使系统了解定时器事件所需的精度。误差值为系统管理功耗和唤醒内核提供了一定的灵活性。例如，系统可能会使用误差值来提前或者延迟触发时间，并将其与其他系统事件更好地对齐。因此，我们应该尽可能为定时器指定一个误差值。

> **注意**：即使我们指定误差值为0，也绝对不要期望一个定时器在要求的精确纳秒下触发。系统会尽最大努力满足我们的需求，但并不能保证准确的触发时间。
