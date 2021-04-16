// 返回一个特殊队列, 这个队列, 一般不需要暴露出去使用, 而是直接用在了需要 Sequence 的接口里面.
public func zip<Sequence1, Sequence2>(
    _ sequence1: Sequence1, _ sequence2: Sequence2
) -> Zip2Sequence<Sequence1, Sequence2> {
    return Zip2Sequence(sequence1, sequence2)
}

public struct Zip2Sequence<Sequence1: Sequence, Sequence2: Sequence> {
    internal let _sequence1: Sequence1
    internal let _sequence2: Sequence2
    
    internal init(_ sequence1: Sequence1, _ sequence2: Sequence2) {
        (_sequence1, _sequence2) = (sequence1, sequence2)
    }
}

// 一个特殊的, 作为 Zip 的 Iterator
extension Zip2Sequence {
    public struct Iterator {
        internal var _baseStream1: Sequence1.Iterator
        internal var _baseStream2: Sequence2.Iterator
        // 专门要有这样的一个值, 记录一下是否到达了一段的末尾.
        // 这是因为, next 会消耗原来的 sequence.
        // 从能性能上说, 无端的消耗, 没有必要.
        // 从表现来说, A,B 两个 Seq 给到 Zip, 命名 B 已经结束了, Zip 的 Iter 还可以消耗 A 的值. 这不符合 zip 的定义
        internal var _reachedEnd: Bool = false
        
        internal init(
            _ iterator1: Sequence1.Iterator,
            _ iterator2: Sequence2.Iterator
        ) {
            (_baseStream1, _baseStream2) = (iterator1, iterator2)
        }
    }
}

extension Zip2Sequence.Iterator: IteratorProtocol {
    public typealias Element = (Sequence1.Element, Sequence2.Element)
    public mutating func next() -> Element? {
        // The next() function needs to track if it has reached the end.  If we
        // didn't, and the first sequence is longer than the second, then when we
        // have already exhausted the second sequence, on every subsequent call to
        // next() we would consume and discard one additional element from the
        // first sequence, even though next() had already returned nil.
        
        // 上面清楚的说明了, 为什么需要 _reachedEnd 的原因, 就是不要消耗 the longer 的 sequence
        if _reachedEnd {
            return nil
        }
        
        guard let element1 = _baseStream1.next(),
              let element2 = _baseStream2.next() else {
            _reachedEnd = true
            return nil
        }
        return (element1, element2)
    }
}

extension Zip2Sequence: Sequence {
    public typealias Element = (Sequence1.Element, Sequence2.Element)
    public __consuming func makeIterator() -> Iterator {
        return Iterator(
            _sequence1.makeIterator(),
            _sequence2.makeIterator())
    }
    
    public var underestimatedCount: Int {
        return Swift.min(
            _sequence1.underestimatedCount,
            _sequence2.underestimatedCount
        )
    }
}
