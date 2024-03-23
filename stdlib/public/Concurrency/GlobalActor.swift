import Swift

/// A type that represents a globally-unique actor that can be used to isolate
/// various declarations anywhere in the program.

/// A type that conforms to the `GlobalActor` protocol and is marked with
/// the `@globalActor` attribute can be used as a custom attribute. Such types
/// are called global actor types, and can be applied to any declaration to
/// specify that such types are isolated to that global actor type. When using
/// such a declaration from another actor (or from nonisolated code),
/// synchronization is performed through the shared actor instance to ensure
/// mutually-exclusive access to the declaration.
/*
 /// 一种表示全局唯一 actor 的类型，可以用于隔离程序中的各种声明。

 /// 符合 GlobalActor 协议并标记有 @globalActor 属性的类型可以用作自定义属性。这样的类型称为全局 actor 类型，并且可以应用于任何声明，以指定该类型隔离到该全局 actor 类型。当从另一个 actor（或从非隔离代码）使用这样的声明时，通过共享的 actor 实例进行同步，以确保对声明的互斥访问。
 */
@available(SwiftStdlib 5.1, *)
public protocol GlobalActor {
    /// The type of the shared actor instance that will be used to provide
    /// mutually-exclusive access to declarations annotated with the given global
    /// actor type.
    associatedtype ActorType: Actor
    
    /// The shared actor instance that will be used to provide mutually-exclusive
    /// access to declarations annotated with the given global actor type.
    
    /// The value of this property must always evaluate to the same actor
    /// instance.
    // 必须有一个全局的对象, 来进行 单例的获取.
    static var shared: ActorType { get }
    
    /// The shared executor instance that will be used to provide
    /// mutually-exclusive access for the global actor.
    ///
    /// The value of this property must be equivalent to `shared.unownedExecutor`.
    static var sharedUnownedExecutor: UnownedSerialExecutor { get }
}

@available(SwiftStdlib 5.1, *)
extension GlobalActor {
    public static var sharedUnownedExecutor: UnownedSerialExecutor {
        shared.unownedExecutor
    }
}

