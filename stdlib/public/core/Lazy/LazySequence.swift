/// To add a new lazy sequence operation, extend this protocol with
/// a method that returns a lazy wrapper that itself conforms to
/// `LazySequenceProtocol`.  For example, an eager `scan(_:_:)`
/// method is defined as follows:
///
///     extension Sequence {
///         func scan<Result>(
///             _ initial: Result,
///             _ nextPartialResult: (Result, Element) -> Result
///         ) -> [Result] {
///             var result = [initial]
///             for x in self {
///                 result.append(nextPartialResult(result.last!, x))
///             }
///             return result
///         }
///     }
///
///     struct LazyScanSequence<Base: Sequence, Result>
///         : LazySequenceProtocol
///     {
///         let initial: Result
///         let base: Base
///         let nextPartialResult:
///             (Result, Base.Element) -> Result
///
///         struct Iterator: IteratorProtocol {
///             var base: Base.Iterator
///             var nextElement: Result?
///             let nextPartialResult:
///                 (Result, Base.Element) -> Result
///             
///             mutating func next() -> Result? {
///                 return nextElement.map { result in
///                     nextElement = base.next().map {
///                         nextPartialResult(result, $0)
///                     }
///                     return result
///                 }
///             }
///         }
///         
///         func makeIterator() -> Iterator {
///             return Iterator(
///                 base: base.makeIterator(),
///                 nextElement: initial as Result?,
///                 nextPartialResult: nextPartialResult)
///         }
///     }
///     extension LazySequenceProtocol {
///         func scan<Result>(
///             _ initial: Result,
///             _ nextPartialResult: @escaping (Result, Element) -> Result
///         ) -> LazyScanSequence<Self, Result> {
///             return LazyScanSequence(
///                 initial: initial, base: self, nextPartialResult: nextPartialResult)
///         }
///     }

/*
 以上, 就是如何自定义一个 Lazy 操作符的过程.
 
 RxSwfit 的设计思路不知道是不是从这里来的.
 
 .lazy.map. 返回的是一个 Wrapper 的类型.
 这个 Wrapper 的类型, 将 transfom 的操作, 存储到自己的内部.
 */
public protocol LazySequenceProtocol: Sequence {
    associatedtype Elements: Sequence = Self where Elements.Element == Element
    
    /// A sequence containing the same elements as this one, possibly with
    /// a simpler type.
    ///
    /// When implementing lazy operations, wrapping `elements` instead
    /// of `self` can prevent result types from growing an extra
    /// `LazySequence` layer.  For example,
    ///
    /// _prext_ example needed
    ///
    /// Note: this property need not be implemented by conforming types,
    /// it has a default implementation in a protocol extension that
    /// just returns `self`.
    var elements: Elements { get }
}

/// When there's no special associated `Elements` type, the `elements`
/// property is provided.
extension LazySequenceProtocol where Elements == Self {
    public var elements: Self { return self }
}

extension LazySequenceProtocol {
    public var lazy: LazySequence<Elements> {
        return elements.lazy
    }
}

extension LazySequenceProtocol where Elements: LazySequenceProtocol {
    public var lazy: Elements {
        return elements
    }
}

/*
 这就是, Sequence.lazy 返回的实际的内容. 一个 Wrapper.
 各种 .rx, .yd, .kf 都是使用了这个思路, 在完成作用域的限制 .
 */
public struct LazySequence<Base: Sequence> {
    internal var _base: Base
    internal init(_base: Base) {
        self._base = _base
    }
}

/*
 LazySequence 对于 Sequence 的实现, 完全就是调用 base 的实现.
 
 LazySequence 必须实现 Sequence.
 LazyMapSequence 里面存储的, 是一个 Sequence, 在迭代的时候, 它是向 base 询问当前的数据.
 
 sequence.lazy.map.filter.scan
 这一系列的源头, 其实是 sequence.lazy 所产生的 LazySequence 对象.
 所以, LazySequence 必须要实现 Sequence, 向后面的节点输送内容.
 
 而 LazySequence 的实现就是, 它完完全全是一个代理类, 所有对于 Sequence 的实现, 去自己的 base 中询问.
 */

extension LazySequence: Sequence {
    public typealias Element = Base.Element
    public typealias Iterator = Base.Iterator
    
    public __consuming func makeIterator() -> Iterator {
        return _base.makeIterator()
    }
    
    public var underestimatedCount: Int {
        return _base.underestimatedCount
    }
    
    public __consuming func _copyContents(
        initializing buf: UnsafeMutableBufferPointer<Element>
    ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
        return _base._copyContents(initializing: buf)
    }
    
    public func _customContainsEquatableElement(_ element: Element) -> Bool? {
        return _base._customContainsEquatableElement(element)
    }
    
    public __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
        return _base._copyToContiguousArray()
    }
}

extension LazySequence: LazySequenceProtocol {
    public typealias Elements = Base
    public var elements: Elements { return _base }
}

// 这种, wrapper 的概念, 从 swift core 里面就存在了.
extension Sequence {
    public var lazy: LazySequence<Self> {
        return LazySequence(_base: self)
    }
}
