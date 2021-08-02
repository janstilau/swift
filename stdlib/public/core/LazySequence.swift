/// Each time an element
/// of the lazy sequence is accessed, an element of the underlying
/// array is accessed and transformed by the closure.
///
/// Using the `lazy` property gives the standard
/// library explicit permission to store the closure and the sequence
/// in the result, and defer computation until it is needed.
///
/// 这是一个编程的技巧, 数据类型, 返回一个特殊的对象.
/// 这个对象, 其实就是一个包含调用这个的一个盒子.
/// 然后所有的扩展, 都在这个盒子上.
/// 这个技巧用的很广.
/// Lazy 是装饰器模式的有代表性的使用.
/// Lazy Map, Lazy Filter, 都是 Sequence, 所以能够表现得像是一个 Sequence, 同时, 里面又都有一个 Sequence.
/// 每一个特殊的 lazy Sequence , 都是存储自己业务相关的逻辑, 然后, 调用 base 的进行取值, 然后使用业务进行加工后返回.
public protocol LazySequenceProtocol: Sequence {
    associatedtype Elements: Sequence = Self where Elements.Element == Element
    var elements: Elements { get }
}

/// When there's no special associated `Elements` type, the `elements`
/// property is provided.
extension LazySequenceProtocol where Elements == Self {
    /// Identical to `self`.
    @inlinable // protocol-only
    public var elements: Self { return self }
}

// Array -> lazy, 产生 LazySequence<Array>
// LazySequence<Array> -> lazy, 因为 Array 不是 LazySequenceProtocol, 产生一个新的 LazySequence<Array>
// LazyMapSequence<LazySequence<Array>>, 因为, LazySequence<Array> 已经是 lazy 的了, 返回 LazySequence<Array>, 这样避免了多次调用 lazy, 无限生成 lazySequence
extension LazySequenceProtocol {
    @inlinable // protocol-only
    public var lazy: LazySequence<Elements> {
        return elements.lazy
    }
}

extension LazySequenceProtocol where Elements: LazySequenceProtocol {
    @inlinable // protocol-only
    public var lazy: Elements {
        return elements
    }
}

// 一个特殊的类型, 保存了对于 base sequence 的引用
public struct LazySequence<Base: Sequence> {
    @usableFromInline
    internal var _base: Base
    @inlinable // lazy-performance
    internal init(_base: Base) {
        self._base = _base
    }
}

// LazySequence 中, 对于 Sequence 的实现, 都是交给了 base 进行处理.
// 对于 Lazy Sequence 而然, 它里面的所有数据类型, 都和它包装的 Sequence 一样.
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

// LazySequence 对于 LazySequenceProtocol 的适配
// 对于 LazySequence 而然, Elements 很固定, 就是 Base.
extension LazySequence: LazySequenceProtocol {
    public typealias Elements = Base
    @inlinable // lazy-performance
    public var elements: Elements { return _base }
}

// 原始的 Sequence, 没有被 lazy 包装过的, 返回一个 LazySequence 然后把自己包装进去.
extension Sequence {
    /// A sequence containing the same elements as this sequence,
    /// but on which some operations, such as `map` and `filter`, are
    /// implemented lazily.
    @inlinable // protocol-only
    public var lazy: LazySequence<Self> {
        return LazySequence(_base: self)
    }
}
