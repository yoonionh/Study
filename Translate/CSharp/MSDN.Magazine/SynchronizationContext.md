#병렬 컴퓨팅 - SynchronizationContext에 관한 모든것

>#Parallel Computing - It's All About the SynchronizationContext

By [Stephen Cleary](https://msdn.microsoft.com/en-us/magazine/mt149362?author=stephen+cleary) | February 2011

멀티 스레드 프로그래밍은 매우 어렵습니다.
제대로 이해하기 위해서는 어마어마한 양의 개념과 도구들을 학습해야 합니다.
**Microsoft .NET Framework**은 `SynchronizationContext` 클래스를 제공 합니다. 
불행히도, 많은 개발자들이 이 유용한 도구를 모르고 있습니다.

>Multithreaded programming can be quite difficult, and there’s a tremendous body of concepts and tools to learn when one embarks on this task. To help out, the Microsoft .NET Framework provides the SynchronizationContext class. Unfortunately, many developers aren’t even aware of this useful tool.

플랫폼에 상관없이 (ASP. NET, Windows Presentation Foundation, Windows 폼 (WPF), Silverlight 등) 
.NET 프로그램에는 `SynchronizationContext`의 개념이 포함 되어 있으므로,
다중 스레드를 개발할 경우 `SynchronizationContext`를 이해하고 활용할 수 있는 해택을 누릴 수 있습니다.

>Regardless of the platform—whether it’s ASP.NET, Windows Forms, Windows Presentation Foundation (WPF), Silverlight or others—all .NET programs include the concept of SynchronizationContext, and all multithreading programmers can benefit from understanding and applying it.

##**SynchronizationContext**에 대한 필요성

>##The Need for SynchronizationContext

다중 스레드 프로그램은 **.NET Framework**가 등장하기 훨씬 이전부터 있었습니다.
이 경우 한 스레드에서 다른 스레드로 작업을 전송해야 할 경우가 종종 있습니다.
Windows 프로그램은 **메시지 루프**를 중심으로 동작하기 때문에,
많은 개발자들은 **윈도우 메시지 큐**로 작업을 전달했습니다.
**윈도우 메세지 큐**에서 처리가능한 형태로 **사용자정의 윈도우 메세지**를 정의하여야 했습니다.

>Multithreaded programs existed well before the advent of the .NET Framework. These programs often had the need for one thread to pass a unit of work to another thread. Windows programs were centered on message loops, so many programmers used this built-in queue to pass units of work around. Each multithreaded program that wanted to use the Windows message queue in this fashion had to define its own custom Windows message and convention for handling it.

.NET Framework가 처음 나왔을 때에는 이런 식의 방법이 표준이었습니다.
그땐 .NET이 지원하는 GUI 어플리케이션은 **Windows Form** 뿐 이었습니다.
그러나, 프레임워크 개발자는 다른 방식의 등장을 예상하고, 범용 솔루션을 개발했습니다.
그래서 탄생한 것이 `ISynchronizeInvoke`입니다.

>When the .NET Framework was first released, this common pattern was standardized. At that time, the only GUI application type that .NET supported was Windows Forms. However, the framework designers anticipated other models, and they developed a generic solution. ISynchronizeInvoke was born.

`ISynchronizeInvoke`의 기본 개념은 다음과 같습니다.
"소스" 스레드는 "타겟" 스레드에서 `delegate`를 큐에 추가하고
필요에 따라 해당 `delegate`의 작업이 끝나기를 기다리게 하는 것입니다.
`ISynchronizeInvoke` 역시 "현재 코드"가 "타겟 스레드"에서 실행되고 있는지 여부를 판단할 수 있는 속성이 제공됩니다.
(이미 실행 중인 경우 `delegate`를 큐에 저장할 필요가 없습니다).
 **Windows Form**은 `ISynchronizeInvoke`를 이용한 구현만을 제공하고,
그 패턴은 비동기 구성 요소를 설계하기 위해 개발되었으므로,
전혀 문제가 되지 않았습니다.

>The idea behind ISynchronizeInvoke is that a “source” thread can queue a delegate to a “target” thread, optionally waiting for that delegate to complete. ISynchronizeInvoke also provided a property to determine whether the current code was already running on the target thread; in this case, queuing up the delegate would be unnecessary. Windows Forms provided the only implementation of ISynchronizeInvoke, and a pattern was developed for designing asynchronous components, so everyone was happy.

**.NET Framework 2.0**에는 전면적인 변경사항들이 포함되었습니다.
주요 개선점 중 하나는 **ASP.NET**에서 **비동기 페이지** 구현이 가능해 졌습니다.
**.NET Framework 2.0** 이전에는 모든 **ASP.NET** `request`는 완료 될 때까지 스레드를 가지고 있어야 했습니다.
참 비효율적이었죠.
왜냐면 웹 페이지를 만드는 과정에서 **데이터베이스 쿼리**나 **웹 서비스 호출**을 사용하는 경우가 많고,
웹 페이지 생성 `request`를 처리하는 스레드는 작업이 완료 될 때까지 기다려야 합니다.
비동기 페이지에서는 `request`를 처리하는 스레드는 각각의 작업을 시작한 다음 **ASP.NET 스레드 풀**로 반환됩니다.
작업이 완료되면 **ASP.NET 스레드 풀**의 아무 스레드에서든 해당 `request`를 완료할 수 있습니다.

>Version 2.0 of the .NET Framework contained many sweeping changes. One of the major improvements was introducing asynchronous pages to the ASP.NET architecture. Prior to the .NET Framework 2.0, every ASP.NET request needed a thread until the request was completed. This was an inefficient use of threads, because creating a Web page often depends on database queries and calls to Web services, and the thread handling that request would have to wait until each of those operations finished. With asynchronous pages, the thread handling the request could begin each of the operations and then return back to the ASP.NET thread pool; when the operations finished, another thread from the ASP.NET thread pool would complete the request.

그러나 `ISynchronizeInvoke`는 **ASP.NET 비동기 페이지 구조**에는 적합하지 않았습니다.
`ISynchronizeInvoke` 패턴을 사용하여 개발한 비동기 구성요소는 **ASP.NET** 페이지에서는 제대로 작동하지 않습니다.
비동기 페이지는 큐에 있는 작업을 원래 스레드로 전달하는 대신에, 페이지 `request` 작업을 완료할 수 있다고 판단되는 작업들의 수만 관리하면 됩니다.
그래서 많이 심사숙고한 결과, `SynchronizationContext`가 `ISynchronizeInvoke`를 대체하게 되었습니다.

>However, ISynchronizeInvoke wasn’t a good fit for the ASP.NET asynchronous pages architecture. Asynchronous components developed using the ISynchronizeInvoke pattern wouldn’t work correctly within ASP.NET pages because ASP.NET asynchronous pages aren’t associated with a single thread. Instead of queuing work to the original thread, asynchronous pages only need to maintain a count of outstanding operations to determine when the page request can be completed. After much thought and careful design, ISynchronizeInvoke was replaced by SynchronizationContext.

##`SynchronizationContext`의 개념

>##The Concept of SynchronizationContext

`ISynchronizeInvoke`에는 2가지 요구조건이 있는데,
동기화가 필요한지 판단 가능한지와
스레드 간의 작업을 queue로 전달가능하냐는 것입니다.
`SynchronizationContext`는 `ISynchronizeInvoke`를 대체하려고 만들었지만 설계하는 과정에서 완벽하게 대체하지 못하도록 바뀌었습니다.

>ISynchronizeInvoke satisfied two needs: determining if synchronization was necessary, and queuing a unit of work from one thread to another. SynchronizationContext was designed to replace ISynchronizeInvoke, but after the design process, it turned out to not be an exact replacement.

`SynchronizationContext`의 첫번째 특징은 큐에 있는 작업을 `context`에 재공한다는 것입니다.
(특정 스레드가 아닌 `context`에 제공을 한다는게 중요합니다.)
`SynchronizationContext`의 구현이 특정한 하나의 스레드에 연결되지 않으므로 그 차이는 매우 중요합니다.
`SynchronizationContext`는 동기화 필요여부를 판단하는 방법을 가지지 않는데, 왜냐면 그 판단이 항상 가능한 것은 아니기 때문입니다.

>One aspect of SynchronizationContext is that it provides a way to queue a unit of work to a context. Note that this unit of work is queued to a context rather than a specific thread. This distinction is important, because many implementations of SynchronizationContext aren’t based on a single, specific thread. SynchronizationContext does not include a mechanism to determine if synchronization is necessary, because this isn’t always possible.

두 번째 특징은 모든 스레드는 `"current" context`를 가진다는 것입니다.
그 `context`가 반드시 `unique`할 필요는 없으며 다른 스레드와 공유할 수도 있습니다.
드물긴 하지만, 스레드가 `current context`를 변경하는 것도 가능합니다.

>Another aspect of SynchronizationContext is that every thread has a “current” context. A thread’s context isn’t necessarily unique; its context instance may be shared with other threads. It’s possible for a thread to change its current context, but this is quite rare.

세 번째 특징은 완료되지 않은 비동기 작업의 수를 제한한다는 것입니다.
그러므로 ASP.NET 비동기 페이지 사용나 이런 종류의 작업 수 제한이 필요로하는 다른 호스트에서 사용이 가능합니다.
대부분의 경우 `SynchronizationContext`가 발생하면 `count`는 증가하며, 작업이 끝났다고 `context`에게 통보하면서 감소합니다.

>A third aspect of SynchronizationContext is that it keeps a count of outstanding asynchronous operations. This enables the use of ASP.NET asynchronous pages and any other host needing this kind of count. In most cases, the count is incremented when the current SynchronizationContext is captured, and the count is decremented when the captured SynchronizationContext is used to queue a completion notification to the context.

다른 특징들도 있으나, 개발자 입장에서 그다지 고려할 필요가 없습니다.
가장 중요한 특징에 대해서는 아래 **그림 1**로 표현하였습니다.

>There are other aspects of SynchronizationContext, but they’re less important to most programmers. The most important aspects are illustrated in Figure 1.

####그림 1. `SynchronizationContext` API의 주요 특징
```C#
class SynchronizationContext
{
  // context에 작업을 전달
  void Post(..); // (비동기)
  void Send(..); // (동기)

  // 비동기 작업 수를 계산
  void OperationStarted();
  void OperationCompleted();

  // 각각의 스레드는 current context를 가짐
  // "Current"가 null이면 "new SynchronizationContext()"

  static SynchronizationContext Current { get; }
  static void SetSynchronizationContext(SynchronizationContext);
}
```

>####Figure 1 Aspects of the SynchronizationContext API

```C#
class SynchronizationContext
{
  // Dispatch work to the context.
  void Post(..); // (asynchronously)
  void Send(..); // (synchronously)

  // Keep track of the number of asynchronous operations.
  void OperationStarted();
  void OperationCompleted();

  // Each thread has a current context.
  // If "Current" is null, then the thread's current context is
  // "new SynchronizationContext()", by convention.

  static SynchronizationContext Current { get; }
  static void SetSynchronizationContext(SynchronizationContext);
}
```

##`SynchronizationContext` 구현

>##The Implementations of SynchronizationContext

`SynchronizationContext`의 실제 "context"를 명확하게 정의하긴 힘듭니다.
각각의 프레임워크와 호스트에서 그들만의 `context`를 정의할 수 있습니다.
이런 구현과 한계에 관한 차이점을 정확하게 이해하는 것이 `SynchronizationContext`이 보장하는 것과 보장해 주지 않는 것에 대해서 명확하게 이해하는데 도움이 됩니다.
이 각각의 차이점에 대해서 간략하게 살펴보도록 하겠습니다.

>The actual “context” of the SynchronizationContext isn’t clearly defined. Different frameworks and hosts are free to define their own context. Understanding these different implementations and their limitations clarifies exactly what the SynchronizationContext concept does and doesn’t guarantee. I’ll briefly discuss some of these implementations.

###WindowsFormsSynchronizationContext
**(System.Windows.Forms.dll: System.Windows.Forms)**

윈도우 앱은 UI 컨트럴을 다루는 스레드의 `current context`로 `WindowsFormsSynchronizationContext`를 생성합니다.
`WindowsFormsSynchronizationContext`는 UI 컨트럴용으로 `ISynchronizeInvoke` 메서드를 사용합니다.
`ISynchronizeInvoke` 메서드는 `Win32 메세지 루프`로 `delegate`를 전달하는 역할을 수행합니다
`WindowsFormsSynchronizationContext`의 `context`는 단일 UI 스레드 입니다.

>Windows Forms apps will create and install a WindowsFormsSynchronizationContext as the current context for any thread that creates UI controls. This SynchronizationContext uses the ISynchronizeInvoke methods on a UI control, which passes the delegates to the underlying Win32 message loop. The context for WindowsFormsSynchronizationContext is a single UI thread.

`WindowsFormsSynchronizationContext` 큐에 등록된 모든 `delegate`는 한 번에 하나씩 실행됩니다.
따라서 큐에 추가된 순서대로 특정 UI 스레드에서 실행 됩니다.
각각의 UI 스레드 별로 `WindowsFormsSynchronizationContext`를 하나씩 만듭니다.

>All delegates queued to the WindowsFormsSynchronizationContext are executed one at a time; they’re executed by a specific UI thread in the order they were queued. The current implementation creates one WindowsFormsSynchronizationContext for each UI thread.

###DispatcherSynchronizationContext
**(WindowsBase.dll: System.Windows.Threading)**

WPF와 실버라이트 앱은 `DispatcherSynchronizationContext`를 사용하는데,
그것은 `delegate`를 UI 스레드의 디스패처에게 "일반적인" 우선순위로 큐를 통해 전달합니다.
이 `SynchronizationContext`는 `Dispatcher.Run`을 통해 스레드가 디스패처 루프를 시작할때 `current context`처럼 설정됩니다.
`DispatcherSynchronizationContext`의 `context`는 단일 UI 스레드입니다.

>WPF and Silverlight applications use a DispatcherSynchronizationContext, which queues delegates to the UI thread’s Dispatcher with “Normal” priority. This SynchronizationContext is installed as the current context when a thread begins its Dispatcher loop by calling Dispatcher.Run. The context for DispatcherSynchronizationContext is a single UI thread.

`DispatcherSynchronizationContext` 큐에 등록된 모든 `delegate`는 등록된 순서대로 한 번에 하나씩 UI 스레드에서 실행됩니다.
각각의 최상위 Window 마다 하나의 `DispatcherSynchronizationContext`를 만듭니다.
(모든 최상위 Windows가 같은 Dispatcher를 공유 하는 경우에도 마찬가지입니다.)

>All delegates queued to the DispatcherSynchronizationContext are executed one at a time by a specific UI thread in the order they were queued. The current implementation creates one DispatcherSynchronizationContext for each top-level window, even if they all share the same underlying Dispatcher.

###Default (ThreadPool) SynchronizationContext
**(mscorlib.dll: System.Threading)**

`SynchronizationContext`이 기본입니다.
스래드의 현재 `SynchronizationContext`가 `null`인 경우 기본 `SynchronizationContext`를 가집니다.

>The default SynchronizationContext is a default-constructed SynchronizationContext object. By convention, if a thread’s current SynchronizationContext is null, then it implicitly has a default SynchronizationContext.

기본 `SynchronizationContext`는 비동기 `delegate`는 ThreadPool에 등록하고, 동기 `delegate`는 호출 스레드에서 직접 실행 합니다.
따라서 그 `context`는 `Send`를 실행한 스레드 만큼이나 모든 ThreadPool의 스레드를 대상으로 합니다.
`context`는 `Send`를 실행한 스레드를 "빌려서" `delegate`가 완료될때까지 `context` 내부에서 사용합니다.
즉, 기본 `context`는 프로세스 상의 어떤 스레드에서도 실행 될 수 있습니다.

>The default SynchronizationContext queues its asynchronous delegates to the ThreadPool but executes its synchronous delegates directly on the calling thread. Therefore, its context covers all ThreadPool threads as well as any thread that calls Send. The context “borrows” threads that call Send, bringing them into its context until the delegate completes. In this sense, the default context may include any thread in the process.

기본 `SynchronizationContext`는 **ASP.NET**에서 호스팅하지 않는 경우 ThreadPool의 스레드에 적용됩니다.
기본 `SynchronizationContext`는 자식 스레드가 따로 `SynchronizationContext`를 설정하지 않은 경우 (Thread 클래스의 인스턴스가 아니라) 자식 스레드에 적용됩니다.
그리고, UI 앱은 보통 2개의 동기 `context`를 사용합니다.
`UI SynchronizationContext`는 UI 스레드를 동작시키며, 기본 `SynchronizationContext`는 ThreadPool 스레드를 수용합니다.

>The default SynchronizationContext is applied to ThreadPool threads unless the code is hosted by ASP.NET. The default SynchronizationContext is also implicitly applied to explicit child threads (instances of the Thread class) unless the child thread sets its own SynchronizationContext. Thus, UI applications usually have two synchronization contexts: the UI SynchronizationContext covering the UI thread, and the default SynchronizationContext covering the ThreadPool threads.

기본 `SynchronizationContext`에서는 이벤트 기반 비동기 요소들이 거의 제대로 작동하지 않습니다.
대표적인 예로 UI 앱에서 *BackgroundWorker*가 다른 *BackgroundWorker*를 시작하는 것을 들 수 있습니다.
각 *BackgroundWorker*는 `RunWorkerAsync`를 호출하는 스레드의 `SynchronizationContext`에 의해서 동작하고, 그 후에 해당 `context`안에서 `RunWorkerCompleted event`를 실행합니다.
UI 작업용 `SynchronizationContext`인 경우에는 대게 *BackgroundWorker*가 하나여서, `RunWorkerAsync`로 획득한 UI `context`가 `RunWorkerCompleted`를 실행합니다.
(그림 2 참고)

>Many event-based asynchronous components don’t work as expected with the default SynchronizationContext. An infamous example is a UI application where one BackgroundWorker starts another BackgroundWorker. Each BackgroundWorker captures and uses the SynchronizationContext of the thread that calls RunWorkerAsync and later executes its RunWorkerCompleted event in that context. In the case of a single BackgroundWorker, this is usually a UI-based SynchronizationContext, so RunWorkerCompleted is executed in the UI context captured by RunWorkerAsync (see Figure 2).

![image: A Single BackgroundWorker in a UI Context](https://github.com/DevStarSJ/Study/blob/master/Translate/CSharp/MSDN.Magazine/image/SynchronizationContext.01.jpg?raw=true)

####그림 2 UI `Context`에 *BackgroundWorker*가 하나인 경우

>####Figure 2 A Single BackgroundWorker in a UI Context

그러나 *BackgroundWorker*가 *DoWork* 핸들러를 통해 다른 *BackgroundWorker*를 시작할 경우,
중첩된 *BackgroundWorker*는 `UI SynchronizationContext`를 캡처하지 않습니다.
*DoWork*는 ThreadPool의 기본 `SynchronizationContext` 스레드에서 실행됩니다.
이 경우 중첩된 *RunWorkerAsync*는 기본 `SynchronizationContext`를 캡처하기 때문에 UI 스레드가 아니라 ThreadPool 스레드에 의해 `RunWorkerCompleted`를 실행합니다.
(그림 3 참고)

>However, if the BackgroundWorker starts another BackgroundWorker from its DoWork handler, then the nested BackgroundWorker doesn’t capture the UI SynchronizationContext. DoWork is executed by a ThreadPool thread with the default SynchronizationContext. In this case, the nested RunWorkerAsync will capture the default SynchronizationContext, so it will execute its RunWorkerCompleted on a ThreadPool thread instead of a UI thread (see Figure 3).

![image: Nested BackgroundWorkers in a UI Context](https://github.com/DevStarSJ/Study/blob/master/Translate/CSharp/MSDN.Magazine/image/SynchronizationContext.02.jpg?raw=true)

####그림 3 UI `Context`에 중첩된 *BackgroundWorker*들

>####Figure 3 Nested BackgroundWorkers in a UI Context

기본적으로 콘솔 앱 및 Windows 서비스는 기본 `SynchronizationContext`만 사용합니다.
따라서 일부 이벤트 기반 비동기 작업에서 오류가 발생 합니다.
한 가지 해결 방법은 명시적으로 자식 스레드를 만들어서 `SynchronizationContext`를 생성하여 이러한 요소들을 위한 `context`를 제공하는 것입니다.
`SynchronizationContext` 구현에 대해서는 여기에서 다루지 않겠습니다만,
**Nito.Async 라이브러리**(<http://nitoasync.codeplex.com>)의 ActionThread 클래스를 보시면 범용 `SynchronizationContext`의 구현으로 사용된 것을 확인할 수 있습니다.

>By default, all threads in console applications and Windows Services only have the default SynchronizationContext. This causes some event-based asynchronous components to fail. One solution for this is to create an explicit child thread and install a SynchronizationContext on that thread, which can then provide a context for these components. Implementing a SynchronizationContext is beyond the scope of this article, but the ActionThread class of the Nito.Async library (nitoasync.codeplex.com) may be used as a general-purpose SynchronizationContext implementation.

###AspNetSynchronizationContext
**(System.Web.dll: System.Web [internal class])**

**ASP.NET** `SynchronizationContext`는 실행된 페이지상의 ThreadPool 스레드에 설치됩니다.
`delegate`가 `AspNetSynchronizationContext`에 등록되면, 원래 페이지의 ID와 무화권 정보 등을 복원한 다음 `delegate`를 직접 실행합니다.
설령 `delegate`가 `Post`를 통해 "비동기적"으로 전달되더라도 직접적으로 실행됩니다.

>The ASP.NET SynchronizationContext is installed on thread pool threads as they execute page code. When a delegate is queued to a captured AspNetSynchronizationContext, it restores the identity and culture of the original page and then executes the delegate directly. The delegate is directly invoked even if it’s “asynchronously” queued by calling Post.


`AspNetSynchronizationContext`의 `context`는 개념은 복잡합니다.
비동기 페이지가 실행되는 동안  `context`는 **ASP.NET** ThreadPool에서 하나의 스레드로 시작합니다.
비동기 `request`가 시작된 다음에, `context`는 어느 스레드도 포함하지 않게 됩니다.
비동기 `request`가 완료되면, ThreadPool 스레드들은 실행을 완료한 다음 `context`에 들어갑니다.
`request`를 전달받은 스레드들은 같은 스레드 일수도 있지만, 대부분의 경우에는 작업완료 시점에 사용되고 있지 않는 스레드입니다.

>Conceptually, the context of AspNetSynchronizationContext is complex. During the lifetime of an asynchronous page, the context starts with just one thread from the ASP.NET thread pool. After the asynchronous requests have started, the context doesn’t include any threads. As the asynchronous requests complete, the thread pool threads executing their completion routines enter the context. These may be the same threads that initiated the requests but more likely would be whatever threads happen to be free at the time the operations complete.


동일한 응용 프로그램에서 여러 작업이 동시에 완료되면, `AspNetSynchronizationContext`는 항상 완료된 작업을 한 번에 하나씩 실행합니다.
작업을 실행하는 스레드는 특별한 지정없이 아무 스레드에서나 가능하지만, 실행하는 스레드는 원래 페이지의 ID와 문화권 정보등을 가지고 있습니다.

>If multiple operations complete at once for the same application, AspNetSynchronizationContext will ensure that they execute one at a time. They may execute on any thread, but that thread will have the identity and culture of the original page.

일반적인 예를 들어보자면 비동기 페이지 내에서 사용되는 `WebClient`가 있습니다.
`DownloadDataAsync`는 현재 `SynchronizationContext`를 캡처하고 이후에 `DownloadDataCompleted` 이벤트를 해당 컨텍스트 내에서 수행할 것입니다.
페이지가 실행되면 **ASP.NET**은 하나의 스레드를 할당하고 해당 페이지의 코드를 실행합니다.

페이지는 `DownloadDataAsync`를 호출(`invoke`)한 반환(`return`)할 수 있습니다.
이 경우 **ASP.NET**이 완료되지 않은 비동기 작업의 수를 관리하기 때문에
해당 페이지 실행이 완료되지 않은 것으로 인식하게 됩니다.
`WebClient` 개체가 요청한 데이터를 다운로드할 때 스레드 풀의 스레드에게 알림이 전달될 것입니다.
이 스레드는 캡처된 컨텍스트 내에서 `DownloadDataCompleted` 이벤트를 발생시킵니다.
컨텍스트는 동일한 스레드에 여전히 머물지만 이벤트 처리기가 올바른 ID 및 문화권으로 실행 되는걸 보장합니다.

>One common example is a WebClient used from within an asynchronous Web page. DownloadDataAsync will capture the current SynchronizationContext and later will execute its DownloadDataCompleted event in that context. When the page begins executing, ASP.NET will allocate one of its threads to execute the code in that page. The page may invoke DownloadDataAsync and then return; ASP.NET keeps a count of the outstanding asynchronous operations, so it understands that the page isn’t complete. When the WebClient object has downloaded the requested data, it will receive notification on a thread pool thread. This thread will raise DownloadDataCompleted in the captured context. The context will stay on the same thread but will ensure the event handler runs with the correct identity and culture.


##`SynchronizationContext` 구현에 대한 고려사항

>##Notes on SynchronizationContext Implementations

`SynchronizationContext`는 다양한 프레임워크 내에서 실행되는 구성 요소를 만드는 방법을 제공합니다.
앞서 살펴본 `BackgroundWorker`와 `WebClient`는 윈도우폼, WPF, Silverlight, 콘솔, ASP.NET 등의 영역에서 동작하는 구성 요소의 예입니다.
그러나 이러한 재사용 가능한 구성 요소를 디자인할 때에는 몇가지 고려해야할 사항들이 있습니다.

>SynchronizationContext provides a means for writing components that may work within many different frameworks. BackgroundWorker and WebClient are two examples that are equally at home in Windows Forms, WPF, Silverlight, console and ASP.NET apps. However, there are some points that must be kept in mind when designing such reusable components.


일반적으로는 `SynchronizationContext`의 구현은 평등성을 비교(equality-comparable)할 수 없습니다.
즉, `ISynchronizeInvoke.InvokeRequired`에 대해서 동등한것은 없습니다.
하지만, 이것이 큰 단점은 아닙니다.
코드는 더 깔끔하고 다른 컨텍스트에서 실행되는 대신에 이미 알려진 컨텍스트에서 항상 실행된다는 것을 확인하기 쉽게 됩니다.

>Generally speaking, SynchronizationContext implementations aren’t equality-comparable. This means that there’s no equivalent to ISynchronizeInvoke.InvokeRequired. However, this isn’t a tremendous drawback; code is cleaner and easier to verify if it always executes within a known context instead of attempting to handle multiple contexts.


모든 `SynchronizationContext`의 구현이 `delegate`의 실행 순서나 동기화에 대해서 보장하지는 않습니다.
UI 기반 `SynchronizationContext` 구현은 모든 조건들에 대해서 확실히 보장하지만, **ASP.NET**의 `SynchronizationContext`는 동기화 순서만 보장합니다.
기본 `SynchronizationContext`는 둘 다 보장하지 않습니다.

>Not all SynchronizationContext implementations guarantee the order of delegate execution or synchronization of delegates. The UI-based SynchronizationContext implementations do satisfy these conditions, but the ASP.NET SynchronizationContext only provides synchronization. The default SynchronizationContext doesn’t guarantee either order of execution or synchronization.


`SynchronizationContext` 객체와 스레드가 1:1로 대응되지는 않습니다.
`WindowsFormsSynchronizationContext`는 (`SynchronizationContext.CreateCopy`가 호출되지 않는 동안에는) 스레드와 1:1로 매핑됩니다. 
하지만 다른 컨텍스트들은 그렇지 않습니다.
일반적으로, 특정 컨택스트가 특정 스레드에서 실행된다는 가정은 하지 않는게 좋습니다.

>There isn’t a 1:1 correspondence between SynchronizationContext instances and threads. The WindowsFormsSynchronizationContext does have a 1:1 mapping to a thread (as long as SynchronizationContext.CreateCopy isn’t invoked), but this isn’t true of any of the other implementations. In general, it’s best to not assume that any context instance will run on any specific thread.

마지막으로, `SynchronizationContext.Post` 메서드가 꼭 비동기적이어야 할 필요는 없습니다.
대부분의 경우 비동기적으로 구현하고 있지만 `AspNetSynchronizationContext`은 두드러지는 예외입니다.
따라서 예기치 않은 재진입(re-entrancy) 문제가 발생할 수도 있습니다.
이러한 차이점들에 대해서 **그림 4**에서 살펴보도록 하겠습니다.

>Finally, the SynchronizationContext.Post method isn’t necessarily asynchronous. Most implementations do implement it asynchronously, but AspNetSynchronizationContext is a notable exception. This may cause unexpected re-entrancy issues. A summary of these different implementations can be seen in Figure 4.


####그림 4 SynchronizationContext 종류별 요약

|                 | `delegate`를 실행한 특정 스레드 | 배타적 (`delegate`가 한번에 하나씩 실행) | 순서대로 (`delegate`가 등록된 순서대로 실행) | `Send`가 `delegate`를 직접 수행 | `Post`가 `delegate`를 직접 수행 |
|-----------------|-------------------------------|----------------------------------------|-------------------------------------------|--------------------------------|--------------------------------|
| Windows Forms   | Yes                           | Yes                                    | Yes                                       | UI 스레드에서 호출하는 경우      | Never                          |
| WPF/Silverlight | Yes                           | Yes                                    | Yes                                       | UI 스레드에서 호출하는 경우      | Never                          |
| Default         | No                            | No                                     | No                                        | Always                         | Never                          |
| ASP.NET         | No                            | Yes                                    | No                                        | Always                         | Always                         |

>####Figure 4 Summary of SynchronizationContext Implementations
>
>|                 | Specific Thread Used to Execute Delegates | Exclusive (Delegates Execute One at a Time) | Ordered (Delegates Execute in Queue Order) | Send May Invoke Delegate Directly | Post May Invoke Delegate Directly |
|-----------------|-------------------------------------------|---------------------------------------------|--------------------------------------------|-----------------------------------|-----------------------------------|
| Windows Forms   | Yes                                       | Yes                                         | Yes                                        | If called from UI thread          | Never                             |
| WPF/Silverlight | Yes                                       | Yes                                         | Yes                                        | If called from UI thread          | Never                             |
| Default         | No                                        | No                                          | No                                         | Always                            | Never                             |
| ASP.NET         | No                                        | Yes                                         | No                                         | Always                            | Always                            |


##AsyncOperationManager 와 AsyncOperation

>##AsyncOperationManager and AsyncOperation


**.NET Framework**에 있는 `AsyncOperationManager` 클래스와 `AsyncOperation` 클래스는 `SynchronizationContext`를 추상화한 가벼운 래퍼입니다.
`AsyncOperationManager`는 `AsyncOperation`이 처음 만들어질 때 현재 `SynchronizationContext`를 캡처하는데, 만약 `SynchronizationContext`가 *null*이면 기본 `SynchronizationContext`로 생성합니다.
`AsyncOperation`은 `SynchronizationContext`에 캡처된 `delegate`를 비동기적으로 배치합니다.

>The AsyncOperationManager and AsyncOperation classes in the .NET Framework are lightweight wrappers around the SynchronizationContext abstraction. AsyncOperationManager captures the current SynchronizationContext the first time it creates an AsyncOperation, substituting a default SynchronizationContext if the current one is null. AsyncOperation posts delegates asynchronously to the captured SynchronizationContext.


대부분의 이벤트 기반 비동기 구성 요소는 해당 구현에서 `AsyncOperationManager` 클래스와 `AsyncOperation` 클래스를 사용합니다.
두 클래스는 완료되는 시점이 결정된 비동기작업, 즉, 한 시점에서 시작한 후 다른 시점에서 이벤트와 함께 끝나는 경우에는 제대로 작동합니다.
다른 비동기 알림은 완료시점이 명확하지 않을 수 있습니다.
예를 들어, 한 시점에 시작하여 계속 지속되는 구독(subscription) 같은 경우입니다.
이러한 작업에서는 `SynchronizationContext`를 직접 캡쳐하고 사용해야 합니다.

>Most event-based asynchronous components use AsyncOperationManager and AsyncOperation in their implementation. These work well for asynchronous operations that have a defined point of completion—that is, the asynchronous operation begins at one point and ends with an event at another. Other asynchronous notifications may not have a defined point of completion; these may be a type of subscription, which begins at one point and then continues indefinitely. For these types of operations, SynchronizationContext may be captured and used directly.

새 구성 요소는 이벤트 기반 비동기 패턴을 사용하지 않는 것이 좋습니다.
**Visual Studio Async CTP (Community Technology Preview)**에는  작업 기반 비동기 패턴에 대한 설명서가 포함 되어 있으며,
이 패턴은 `SynchronizationContext`로 이벤트를 발생시키지 않고도 구성 요소에서 `Task` 및 `Task<TResult>`개체를 반환합니다.
앞으로는 **작업 기반 API**가 .NET에서의 비동기 프로그래밍의 대표가 될 것입니다.

>New components shouldn’t use the event-based asynchronous pattern. The Visual Studio asynchronous Community Technology Preview (CTP) includes a document describing the task-based asynchronous pattern, in which components return Task and Task<TResult> objects instead of raising events through SynchronizationContext. Task-based APIs are the future of asynchronous programming in .NET.


###`SynchronizationContext`를 지원하는 라이러리의 예

>###Examples of Library Support for SynchronizationContext

`BackgroundWorker`와 `WebClient` 같은 간단한 구성 요소는 `SynchronizationContext`의 캡쳐와 사용을 숨기면서 스스로 암시적으로 이식이 가능합니다.
그러나 대부분의 라이브러리는 `SynchronizationContext`를 좀 더 명시적으로 사용합니다.
`SynchronizationContext`를 사용하는 API를 노출시킴으로서 해당 라이브러리는 프레임워크에 의존적이지 않게 되는 것뿐 아니라, 고급 사용자들에게 확장성을 제공할 수 있게 됩니다.

>Simple components such as BackgroundWorker and WebClient are implicitly portable by themselves, hiding the SynchronizationContext capture and usage. Many libraries have a more visible use of SynchronizationContext. By exposing APIs using SynchronizationContext, libraries not only gain framework independence, they also provide an extensibility point for advanced end users.


여기서 소개 하는 라이브러리에서는 *current* `SynchronizationContext`는 `ExecutionContext`의 일부로 간주하겠습니다.
스레드의 `ExecutionContext`를 캡처하는 모든 시스템은 *current* `SynchronizationContext`를 캡처합니다.
`ExecutionContext`가 복원되면 `SynchronizationContext`도 복원됩니다.

>In addition to the libraries I’ll discuss now, the current SynchronizationContext is considered to be part of the ExecutionContext. Any system that captures a thread’s ExecutionContext captures the current SynchronizationContext. When the ExecutionContext is restored, the SynchronizationContext is usually restored as well.

##Windows Communication Foundation (WCF):UseSynchronizationContext


WCF는 *configure server*와 *client behavior*라는 2개의 속성을 가집니다. (`ServiceBehaviorAttribute`, `CallbackBehaviorAttribute`)
두 속성 다 `UseSynchronizationContext`라는 *bool* 속성을 가집니다 
이 속성의 기본값은 *true*이므로 통신 채널이 생성될 때 *current* `SynchronizationContext`를 캡처하고, 이 캡처된 `SynchronizationContext`은 *contract method*를 큐에 저장 됩니다.

>WCF has two attributes that are used to configure server and client behavior: ServiceBehaviorAttribute and CallbackBehaviorAttribute. Both of these attributes have a Boolean property: UseSynchronizationContext. The default value of this attribute is true, which means that the current SynchronizationContext is captured when the communication channel is created, and this captured SynchronizationContext is used to queue the contract methods.


일반적으로 이것은 정확하게 원하는 동작입니다. 즉, 서버는 기본 `SynchronizationContext`를 사용하고, 클라이언트 콜백은 `SynchronizationContext`의 적절한 UI를 사용합니다.
그러나 클라이언트 콜백을 호출하는 서버 메서드를 클라이언트가 호출하는 경우와 같이 재진입성이 요구될 경우 문제가 발생할 수 있습니다.
이 경우, `UseSynchronizationContext` 속성을 *false*로 설정하여 WCF에 의해 `SynchronizationContext`를 자동으로 사용할 수 없도록 설정할 수 있습니다.

>Normally, this behavior is exactly what is needed: Servers use the default SynchronizationContext, and client callbacks use the appropriate UI SynchronizationContext. However, this can cause problems when re-entrancy is desired, such as a client invoking a server method that invokes a client callback. In this and similar cases, the WCF automatic usage of SynchronizationContext may be disabled by setting UseSynchronizationContext to false.

여기서는 **WCF**가 `SynchronizationContext`를 사용하는 방법에 대해서 간단하게만 살펴보았는데,
자세한 내용을 알고 싶은 분들은 2007년 11월에 **MSDN 매거진**에 수록된 **“Synchronization Contexts in WCF”** (<https://msdn.microsoft.com/magazine/cc163321>)를 보시기 바랍니다.

>This is just a brief description of how WCF uses SynchronizationContext. See the article “Synchronization Contexts in WCF” (<https://msdn.microsoft.com/magazine/cc163321>) in the November 2007 issue of MSDN Magazine for more details.


###Windows Workflow Foundation (WF): WorkflowInstance.SynchronizationContext


원래는 WF 호스트는 WorkflowSchedulerService와 파생 형식을 사용하여 스레드에서 워크플로 작업의 일정을 설정하는 방법을 제어하고 있었습니다.
**.NET Framework 4**로 업그레이드의 일환으로, 이 `WorkflowInstance` 클래스와 이것의 파생 클레스인 `WorkflowApplication`에 `SynchronizationContext` 속성이 포함이 포함되었습니다.

>WF hosts originally used WorkflowSchedulerService and derived types to control how workflow activities were scheduled on threads. Part of the .NET Framework 4 upgrade included the SynchronizationContext property on the WorkflowInstance class and its derived WorkflowApplication class.


호스팅 프로세스가 자체 `WorkflowInstance`를 만들면 `SynchronizationContext`를 직접 설정할 수 있습니다.
`SynchronizationContext`는 `WorkflowInvoker.InvokeAsync` 메서드에서 사용되는데,
이 메서드는 현재 `SynchronizationContext`를 캡처하여 내부 `WorkflowApplication`에 전달합니다.
그런 다음 워크플로 작업와 워크플로 완료 이벤트를 게시하는데 `SynchronizationContext`를 사용합니다.

>The SynchronizationContext may be set directly if the hosting process creates its own WorkflowInstance. SynchronizationContext is also used by WorkflowInvoker.InvokeAsync, which captures the current SynchronizationContext and passes it to its internal WorkflowApplication. This SynchronizationContext is then used to post the workflow completion event as well as the workflow activities.


###Task Parallel Library (TPL): TaskScheduler.FromCurrentSynchronizationContext and CancellationToken.Register

TPL은 `task` 개체 단위로 `TaskScheduler`를 통해 실행합니다.
기본 `TaskScheduler`의 동작은 기본 `SynchronizationContext`와 유사해서 `task`들을 `ThreadPool` 큐에 추가합니다.
TPL이 제공하는 다른 형태의 `TaskScheduler`는 `task`를 `SynchronizationContext` 큐에 등록합니다.
중첩된 `task`를 사용하여 UI를 업데이트 하는 동안 진행 상황을 보고할 수 있습니다 (그림 5 참조).

>The TPL uses task objects as its units of work and executes them via a TaskScheduler. The default TaskScheduler acts like the default SynchronizationContext, queuing the tasks to the ThreadPool. There’s another TaskScheduler provided by the TPL queue that queues tasks to a SynchronizationContext. Progress reporting with UI updates may be done with a nested task, as shown in Figure 5.

####Figure 5 Progress Reporting with UI Updates
```C#
private void button1_Click(object sender, EventArgs e)
{
  // This TaskScheduler captures SynchronizationContext.Current.
  TaskScheduler taskScheduler = TaskScheduler.FromCurrentSynchronizationContext();
  // Start a new task (this uses the default TaskScheduler, 
  // so it will run on a ThreadPool thread).
  Task.Factory.StartNew(() =>
  {
    // We are running on a ThreadPool thread here.
    ; // Do some work.

    // Report progress to the UI.
    Task reportProgressTask = Task.Factory.StartNew(() =>
    {
      // We are running on the UI thread here.
      ; // Update the UI with our progress.
    }, CancellationToken.None,
       TaskCreationOptions.None,
       taskScheduler);

    reportProgressTask.Wait();
  
    ; // Do more work.
  });
}
```

`CancellationToken` 클래스는 **.NET Framework 4**에서 취소작업과 관련된 모든 곳에서 사용됩니다.
기존에 존재하던 취소 형태와 통합하기 위해서, 이 클래스는 취소 요청이 있을 경우 실행되도록 `delegate`에 등록하는 것도 가능합니다.
`delegate`에 등록된 경우 `SynchronizationContext`로 전달될 수 있습니다.
취소 요청을 하면, `CancellationToken`이 `delegate`를 직접 실행하지 않고 `SynchronizationContext` 큐에 추가합니다.

>The CancellationToken class is used for any type of cancellation in the .NET Framework 4. To integrate with existing forms of cancellation, this class allows registering a delegate to invoke when cancellation is requested. When the delegate is registered, a SynchronizationContext may be passed. When the cancellation is requested, CancellationToken queues the delegate to the SynchronizationContext instead of executing it directly.


###Microsoft Reactive Extensions (Rx): ObserveOn, SubscribeOn and SynchronizationContextScheduler


**Rx**는 데이터 스트림을 이벤트처럼 처리하는 라이브러리 입니다.
`ObserveOn` 연산은 이븐트를 `SynchronizationContext` 큐에 추가하며,
`SubscribeOn` 연산은 `SynchronizationContext`를 통해 해당 이벤트에 전달된 구독(subscription)을 큐에 추가합니다.
일반적으로 `ObserveOn` 연산은 이벤트를 통한 UI 업데이트에 사용되며, `SubscribeOn`는 UI 개체에서 발생한 이벤트를 처리하는데 사용됩니다.

>Rx is a library that treats events as streams of data. The ObserveOn operator queues events through a SynchronizationContext, and the SubscribeOn operator queues the subscriptions to those events through a SynchronizationContext. ObserveOn is commonly used to update the UI with incoming events, and SubscribeOn is used to consume events from UI objects.


**Rx**는 `IScheduler` 인터페이스를 이용하여 작업 단위를 큐에 추가하는 독자적인 방법도 가집니다.
`SynchronizationContext`의 큐로 작업을 추가하도록 `IScheduler`를 구현한 `SynchronizationContextScheduler`를 포함하고 있습니다.

>Rx also has its own way of queuing units of work: the IScheduler interface. Rx includes SynchronizationContextScheduler, an implementation of IScheduler that queues to a SynchronizationContext.

###Visual Studio Async CTP: await, ConfigureAwait, SwitchTo and EventProgress<T>


*Microsoft Professional Developers Conference 2010*에서 선보인였듯이 *Visual Studio*가 비동기 코드변환을 지원하게 되었습니다.
기본적으로 현재 `SynchronizationContext`가 `await` 지점에서 캡쳐하고, 준비가 되면 다시 수행을 시작합니다.
(더 정확하게는, 현재 `SynchronizationContext`이 `null`이 아닌 경우에만 캡쳐합니다. 이 경우 현재 `TaskScheduler`를 캡쳐합니다.)

>The Visual Studio support for asynchronous code transformations was announced at the Microsoft Professional Developers Conference 2010. By default, the current SynchronizationContext is captured at an await point, and this SynchronizationContext is used to resume after the await (more precisely, it captures the current SynchronizationContext unless it is null, in which case it captures the current TaskScheduler):

```C#
private async void button1_Click(object sender, EventArgs e)
{
  // SynchronizationContext.Current is implicitly captured by await.
  var data = await webClient.DownloadStringTaskAsync(uri);
  // At this point, the captured SynchronizationContext was used to resume
  // execution, so we can freely update UI objects.
}
```

`ConfigureAwait`는 기본 `SynchronizationContext`의 캡처 동작을 방지하는 방법을 제공합니다.
즉, `flowContext` 매개 변수로 *false*를 전달하면 대기 후 실행을 다시 시작하기 위해 `SynchronizationContext`를 사용하지 않아도 됩니다.
SynchronizationContext 인스턴스에는 `SwitchTo` 라는 확장 메서드도 있는데,
`async` 메소드가 `SwitchTo` 메서드로 실행하고 결과를 기다리는 경우 다른 `SynchronizationContext에`에서 수행하도록 해줍니다.

>ConfigureAwait provides a means to avoid the default SynchronizationContext capturing behavior; passing false for the flowContext parameter prevents the SynchronizationContext from being used to resume execution after the await. There’s also an extension method on SynchronizationContext instances called SwitchTo; this allows any async method to change to a different SynchronizationContext by invoking SwitchTo and awaiting the result.

또한 `IProgress<T>` 인터페이스와 이것의 구현인 `EventProgress<T>` 라는 비동기 연산을 통해서 진행 상황을 보고하는 일반적인 패턴을 소개하고 있습니다.
이 클래스는 생성시 현재 `SynchronizationContext`를 캡처하여 `ProgressChanged` 이벤트를 해당 컨텍스트 내에서 발생 시킵니다.

>The asynchronous CTP introduces a common pattern for reporting progress from asynchronous operations: the IProgress<T> interface and its implementation EventProgress<T>. This class captures the current SynchronizationContext when it’s constructed and raises its ProgressChanged event in that context.


이러한 시원외에도, *void*를 반환하는 `async` 메서드인 시작될 때  경우 비동기 작업 카운트를 증가시키며, 종료시 감소시킵니다. 
비동기 메서드가 void를 반환 하는 메서드의 시작 되는 비동기 작업의 수를 증가 하 고 끝낼 때마다 감소 합니다.
즉, void 반환 `async` 메서드는 최상위 비동기 작업처럼 실행됩니다.

>In addition to this support, void-returning async methods will increment the asynchronous operation count at their start and decrement it at their end. This behavior makes void-returning async methods act like top-level asynchronous operations.

##제한 사항 및 보장되는 사항

>##Limitations and Guarantees


`SynchronizationContext`를 이해하면 개발하는데 도움이 됩니다.
현존하는 크로스플랫폼 구성요소들은 이벤트 동기화에 `SynchronizationContext`를 사용합니다.
라이브러리를 더 향상된 유연성을 제공하기 위해 `SynchronizationContext`를 공개할 것입니다.
SynchronizationContext에 대한 제한 사항 및 보장 사항을 이해 하면 이러한 클래스를 더 잘 만들어 사용할 수 있습니다.

>Understanding SynchronizationContext is helpful for any programmer. Existing cross-framework components use it to synchronize their events. Libraries may expose it to allow advanced flexibility. The savvy coder who understands the limitations and guarantees of SynchronizationContext is better able to write and consume such classes.

---------

원문 : <https://msdn.microsoft.com/en-us/magazine/gg598924.aspx> FEBRUARY 2011 VOLUME 26 NUMBER 02
저자 : **Stephen Cleary** <http://blog.stephencleary.com/>
