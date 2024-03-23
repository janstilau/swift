
import Swift

/*
 Sendable
 
 
 /// A type whose values can safely be passed across concurrency domains by copying.
 ///
 /// You can safely pass values of a sendable type
 /// from one concurrency domain to another ---
 /// for example, you can pass a sendable value as the argument
 /// when calling an actor's methods.
 /// All of the following can be marked as sendable:
 ///
 /// - Value types
 ///
 /// - Reference types with no mutable storage
 ///
 /// - Reference types that internally manage access to their state
 ///
 /// - Functions and closures (by marking them with `@Sendable`)
 ///
 /// Although this protocol doesn't have any required methods or properties,
 /// it does have semantic requirements that are enforced at compile time.
 /// These requirements are listed in the sections below.
 /// Conformance to `Sendable` must be declared
 /// in the same file as the type's declaration.
 ///
 /// To declare conformance to `Sendable` without any compiler enforcement,
 /// write `@unchecked Sendable`.
 /// You are responsible for the correctness of unchecked sendable types,
 /// for example, by protecting all access to its state with a lock or a queue.
 /// Unchecked conformance to `Sendable` also disables enforcement
 /// of the rule that conformance must be in the same file.
 ///
 /// For information about the language-level concurrency model that `Task` is part of,
 /// see [Concurrency][concurrency] in [The Swift Programming Language][tspl].
 ///
 /// [concurrency]: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
 /// [tspl]: https://docs.swift.org/swift-book/
 ///
 /// ### Sendable Structures and Enumerations
 ///
 /// To satisfy the requirements of the `Sendable` protocol,
 /// an enumeration or structure must have only sendable
 /// members and associated values.
 /// In some cases, structures and enumerations
 /// that satisfy the requirements implicitly conform to `Sendable`:
 ///
 /// - Frozen structures and enumerations
 ///
 /// - Structures and enumerations
 ///   that aren't public and aren't marked `@usableFromInline`.
 ///
 /// Otherwise, you need to declare conformance to `Sendable` explicitly.
 ///
 /// Structures that have nonsendable stored properties
 /// and enumerations that have nonsendable associated values
 /// can be marked as `@unchecked Sendable`,
 /// disabling compile-time correctness checks,
 /// after you manually verify that
 /// they satisfy the `Sendable` protocol's semantic requirements.
 ///
 /// ### Sendable Actors
 ///
 /// All actor types implicitly conform to `Sendable`
 /// because actors ensure that all access to their mutable state
 /// is performed sequentially.
 ///
 /// ### Sendable Classes
 ///
 /// To satisfy the requirements of the `Sendable` protocol,
 /// a class must:
 ///
 /// - Be marked `final`
 ///
 /// - Contain only stored properties that are immutable and sendable
 ///
 /// - Have no superclass or have `NSObject` as the superclass
 ///
 /// Classes marked with `@MainActor` are implicitly sendable,
 /// because the main actor coordinates all access to its state.
 /// These classes can have stored properties that are mutable and nonsendable.
 ///
 /// Classes that don't meet the requirements above
 /// can be marked as `@unchecked Sendable`,
 /// disabling compile-time correctness checks,
 /// after you manually verify that
 /// they satisfy the `Sendable` protocol's semantic requirements.
 ///
 /// ### Sendable Functions and Closures
 ///
 /// Instead of conforming to the `Sendable` protocol,
 /// you mark sendable functions and closures with the `@Sendable` attribute.
 /// Any values that the function or closure captures must be sendable.
 /// In addition, sendable closures must use only by-value captures,
 /// and the captured values must be of a sendable type.
 ///
 /// In a context that expects a sendable closure,
 /// a closure that satisfies the requirements
 /// implicitly conforms to `Sendable` ---
 /// for example, in a call to `Task.detached(priority:operation:)`.
 ///
 /// You can explicitly mark a closure as sendable
 /// by writing `@Sendable` as part of a type annotation,
 /// or by writing `@Sendable` before the closure's parameters ---
 /// for example:
 ///
 ///     let sendableClosure = { @Sendable (number: Int) -> String in
 ///         if number > 12 {
 ///             return "More than a dozen."
 ///         } else {
 ///             return "Less than a dozen"
 ///         }
 ///     }
 ///
 /// ### Sendable Tuples
 ///
 /// To satisfy the requirements of the `Sendable` protocol,
 /// all of the elements of the tuple must be sendable.
 /// Tuples that satisfy the requirements implicitly conform to `Sendable`.
 ///
 /// ### Sendable Metatypes
 ///
 /// Metatypes such as `Int.Type` implicitly conform to the `Sendable` protocol.
 
 /// 一种可以通过复制安全地在并发域之间传递的值类型。
  ///
  /// 您可以安全地将可发送类型的值从一个并发域传递到另一个并发域 ---
  /// 例如，您可以在调用 actor 方法时将可发送值作为参数传递。
  /// 以下所有内容都可以标记为可发送：
  ///
  /// - 值类型
  ///
  /// - 没有可变存储的引用类型
  ///
  /// - 内部管理对其状态访问的引用类型
  ///
  /// - 函数和闭包（通过将它们标记为 `@Sendable`）
  ///
  /// 虽然该协议没有任何必需的方法或属性，
  /// 但它确实有在编译时强制执行的语义要求。
  /// 这些要求在下面的各节中列出。
  /// 必须在与类型声明相同的文件中声明对 `Sendable` 的一致性。
  ///
  /// 要声明对 `Sendable` 的一致性而不进行任何编译器强制执行，
  /// 请写 `@unchecked Sendable`。
  /// 您负责未经检查的可发送类型的正确性，
  /// 例如，通过使用锁或队列保护对其状态的所有访问。
  /// 对 `Sendable` 的未经检查的一致性还禁用了强制执行
  /// 一致性必须在同一文件中的规则。
  ///
  /// 有关 `Task` 所属的语言级并发模型的信息，
  /// 请参阅[并发性][concurrency]中的[《Swift 编程语言》][tspl]。
  ///
  /// [concurrency]: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
  /// [tspl]: https://docs.swift.org/swift-book/
  ///
  /// ### 可发送的结构体和枚举
  ///
  /// 要满足 `Sendable` 协议的要求，
  /// 枚举或结构体必须仅具有可发送的成员和相关值。
  /// 在某些情况下，满足要求的结构体和枚举
  /// 隐式符合 `Sendable`：
  ///
  /// - 冻结结构体和枚举
  ///
  /// - 不是公共的并且不是标记为 `@usableFromInline` 的结构体和枚举。
  ///
  /// 否则，您需要明确声明对 `Sendable` 的一致性。
  ///
  /// 具有非可发送存储属性的结构体
  /// 和具有非可发送相关值的枚举可以标记为 `@unchecked Sendable`，
  /// 禁用编译时的正确性检查，
  /// 在您手动验证它们满足 `Sendable` 协议的语义要求后。
  ///
  /// ### 可发送的 Actor
  ///
  /// 所有 actor 类型都隐式符合 `Sendable`
  /// 因为 actor 确保对其可变状态的所有访问都是顺序执行的。
  ///
  /// ### 可发送的类
  ///
  /// 要满足 `Sendable` 协议的要求，
  /// 类必须：
  ///
  /// - 被标记为 `final`
  ///
  /// - 仅包含不可变且可发送的存储属性
  ///
  /// - 没有超类或将 `NSObject` 作为超类
  ///
  /// 标有 `@MainActor` 的类隐式可发送，
  /// 因为主 actor 协调对其状态的所有访问。
  /// 这些类可以具有可变且非可发送的存储属性。
  ///
  /// 不符合上述要求的类
  /// 可以标记为 `@unchecked Sendable`，
  /// 禁用编译时的正确性检查，
  /// 在您手动验证它们满足 `Sendable` 协议的语义要求后。
  ///
  /// ### 可发送的函数和闭包
  ///
  /// 您可以将可发送的函数和闭包标记为 `@Sendable` 属性，
  /// 而不是符合 `Sendable` 协议。
  /// 函数或闭包捕获的任何值都必须是可发送的。
  /// 此外，可发送的闭包必须仅使用按值捕获，
  /// 并且捕获的值必须是可发送类型。
  ///
  /// 在期望可发送闭包的上下文中，
  /// 满足要求的闭包隐式符合 `Sendable` ---
  /// 例如，在调用 `Task.detached(priority:operation:)` 时。
  ///
  /// 您可以通过在类型注释中写入 `@Sendable`，
  /// 或者在闭包参数之前写入 `@Sendable`，
  /// 明确将闭包标记为可发送 ---
  /// 例如：
  ///
  ///     let sendableClosure = { @Sendable (number: Int) -> String in
  ///         if number > 12 {
  ///             return "More than a dozen."
  ///         } else {
  ///             return "Less than a dozen"
  ///         }
  ///     }
  ///
  /// ### 可发送的元组
  ///
  /// 要满足 `Sendable` 协议的要求，
  /// 元组的所有元素必须是可发送的。
  /// 满足要求的元组隐式符合 `Sendable`。
  ///
  /// ### 可发送的元类型
  ///
  /// 例如 `Int.Type` 等元类型隐式符合 `Sendable` 协议。

 
 */
@_implementationOnly import _SwiftConcurrencyShims

/// Common marker protocol providing a shared "base" for both (local) `Actor`
/// and (potentially remote) `DistributedActor` types.
///
/// The `AnyActor` marker protocol generalizes over all actor types, including
/// distributed ones.
/// In practice, this protocol can be used to restrict  protocols, or generic parameters to only be usable with actors, which
/// provides the guarantee that calls may be safely made on instances of given
/// type without worrying about the thread-safety of it -- as they are
/// guaranteed to follow the actor-style isolation semantics.
///
/// While both local and distributed actors are conceptually "actors", there are
/// some important isolation model differences between the two, which make it
/// impossible for one to refine the other.
@_marker
@available(SwiftStdlib 5.1, *)
public protocol AnyActor: AnyObject, Sendable {}

/// Common protocol to which all actors conform.
///
/// The `Actor` protocol generalizes over all `actor` types. Actor types
/// implicitly conform to this protocol.

@available(SwiftStdlib 5.1, *)
public protocol Actor: AnyActor {
    
    /// Retrieve the executor for this actor as an optimized, unowned
    /// reference.
    ///
    /// This property must always evaluate to the same executor for a
    /// given actor instance, and holding on to the actor must keep the
    /// executor alive.
    ///
    /// This property will be implicitly accessed when work needs to be
    /// scheduled onto this actor.  These accesses may be merged,
    /// eliminated, and rearranged with other work, and they may even
    /// be introduced when not strictly required.  Visible side effects
    /// are therefore strongly discouraged within this property.
    nonisolated var unownedExecutor: UnownedSerialExecutor { get }
}

/// Called to initialize the default actor instance in an actor.
/// The implementation will call this within the actor's initializer.
@available(SwiftStdlib 5.1, *)
@_silgen_name("swift_defaultActor_initialize")
public func _defaultActorInitialize(_ actor: AnyObject)

/// Called to destroy the default actor instance in an actor.
/// The implementation will call this within the actor's deinit.
@available(SwiftStdlib 5.1, *)
@_silgen_name("swift_defaultActor_destroy")
public func _defaultActorDestroy(_ actor: AnyObject)

@available(SwiftStdlib 5.1, *)
@_silgen_name("swift_task_enqueueMainExecutor")
@usableFromInline
internal func _enqueueOnMain(_ job: UnownedJob)
