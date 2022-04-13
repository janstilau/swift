/*
 Zip2Sequence 是一个特殊的数据类型.
 大部分的功能, 都是在 Sequence 协议里面添加的.
 Zip2Sequence 通过, 满足 Sequence 的各种限制, 为的是纳入到使用 Sequence 的各种算法里面.
 */
@inlinable // generic-performance
public func zip<Sequence1, Sequence2>( _ sequence1: Sequence1, _ sequence2: Sequence2 )
-> Zip2Sequence<Sequence1, Sequence2> {
    return Zip2Sequence(sequence1, sequence2)
}

public struct Zip2Sequence<Sequence1: Sequence, Sequence2: Sequence> {
    /*
     还是使用了 _ 表示私有的成员变量.
     */
    internal let _sequence1: Sequence1
    internal let _sequence2: Sequence2
    // 使用了元组这种方式, 进行赋值.
    internal init(_ sequence1: Sequence1, _ sequence2: Sequence2) {
        (_sequence1, _sequence2) = (sequence1, sequence2)
    }
}

extension Zip2Sequence {
    public struct Iterator {
        internal var _baseStream1: Sequence1.Iterator
        internal var _baseStream2: Sequence2.Iterator
        internal var _reachedEnd: Bool = false
        internal init(
            _ iterator1: Sequence1.Iterator,
            _ iterator2: Sequence2.Iterator
        ) {
            (_baseStream1, _baseStream2) = (iterator1, iterator2)
        }
    }
}

/*
 每一个类型, 对于协议的实现. 都写到一个单独的 Extension 里面.
 */
extension Zip2Sequence.Iterator: IteratorProtocol {
    public typealias Element = (Sequence1.Element, Sequence2.Element)
    /*
     在 Zip2 的序列里面, 编写 Next 的逻辑.
     */
    public mutating func next() -> Element? {
        // The next() function needs to track if it has reached the end.  If we
        // didn't, and the first sequence is longer than the second, then when we
        // have already exhausted the second sequence, on every subsequent call to
        // next() we would consume and discard one additional element from the
        // first sequence, even though next() had already returned nil.
        
        // 这里注释说了半天, 还是多消耗了长一点的序列里的内容啊. 
        
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

/*
 对于 Sequence 的实现, 也是单独一个 Extension 来实现的.
 */
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
