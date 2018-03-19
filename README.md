# iOS并发编程 -- 并发性和应用程序设计

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
- 将任务异步调度到dispatch queue不会死锁队列。
- 它们的伸缩性更强。
- 串行调度队列为锁和其他同步原函数提供了更高效的替代方案。

提交给dispatch queue的任务必须封装在函数或者block对象中。block对象是OS X v10.6和iOS 4。0中引入的一种C语言特性，它在概念上类似于函数指针，但有一些额外的好处。通常在其他函数或方法中定义block，以便可以从该函数或方法访问其他变量。block也能被移出栈区并复制到堆区，这是将它们提交给dispatch queue时所发生的情况。所有这些语义都可以用较少的代码实现非常动态的任务。

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

在创建一个block操作时，通常在初始化时至少添加一个block，并在稍后根据需要添加更多block。当需要执行`NSBlockOperation`对象时，该操作对象将其所有block对象提交给默认优先级的并发调度队列（concurrent dispatch queue）。操作对象会等待所有block完成执行，当最后一个block完成执行时，操作对象将自身标记为已完成。因此，我们可以使用block操作来跟踪一组正在执行的block，就像使用线程联结合并多个线程的结果一样。区别在于，**因为block操作本身在单独的线程上运行，所以应用程序的其他线程可以在等待block操作完成的同时继续工作。**

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

### 配置相互操作依赖

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

