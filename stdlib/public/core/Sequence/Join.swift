
public struct JoinedSequence<Base: Sequence> where Base.Element: Sequence {
    
    public typealias Element = Base.Element.Element
    internal var _base: Base
    internal var _separator: ContiguousArray<Element>
    
    public init<Separator: Sequence>(base: Base, separator: Separator)
    where Separator.Element == Element {
        self._base = base
        // 在 init 里面, 做了 Separator 的类型转化.
        self._separator = ContiguousArray(separator)
    }
}

extension JoinedSequence {
    public struct Iterator {
        internal var _base: Base.Iterator
        internal var _inner: Base.Element.Iterator?
        internal var _separatorData: ContiguousArray<Element>
        internal var _separator: ContiguousArray<Element>.Iterator?
        
        internal enum _JoinIteratorState {
            case start
            case generatingElements
            case generatingSeparator
            case end
        }
        internal var _state: _JoinIteratorState = .start
        
        public init<Separator: Sequence>(base: Base.Iterator, separator: Separator)
        where Separator.Element == Element {
            self._base = base
            self._separatorData = ContiguousArray(separator)
        }
    }
}

extension JoinedSequence.Iterator: IteratorProtocol {
    public typealias Element = Base.Element.Element
    
    public mutating func next() -> Element? {
        while true {
            switch _state {
            case .start:
                if let nextSubSequence = _base.next() {
                    _inner = nextSubSequence.makeIterator()
                    _state = .generatingElements
                } else {
                    _state = .end
                    return nil
                }
                
                // 在, 抽取序列内容的状态下, 就是不断的使用 _inner 获取内容.
                // 在 _inner 抽取完毕之后, 切换状态, 抽取 _separator 中的内容.
                // 通过 state 的不断变化, 让代码清晰. 
            case .generatingElements:
                // 实际上, 在确定 optinal 不为 nil 的情况下,  使用 ! 也是无可厚非的.
                // 如果在这里, 使用了 optinalBinding, 反而逻辑不是很清晰了.
                let result = _inner!.next()
                if _fastPath(result != nil) {
                    return result
                }
                _inner = _base.next()?.makeIterator()
                if _inner == nil {
                    _state = .end
                    return nil
                }
                if !_separatorData.isEmpty {
                    _separator = _separatorData.makeIterator()
                    _state = .generatingSeparator
                }
                
            case .generatingSeparator:
                let result = _separator!.next()
                if _fastPath(result != nil) {
                    return result
                }
                _state = .generatingElements
                
            case .end:
                return nil
            }
        }
    }
}

extension JoinedSequence: Sequence {
    
    public __consuming func makeIterator() -> Iterator {
        return Iterator(base: _base.makeIterator(), separator: _separator)
    }
    
    public __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
        var result = ContiguousArray<Element>()
        let separatorSize = _separator.count
        
        if separatorSize == 0 {
            for x in _base {
                result.append(contentsOf: x)
            }
            return result
        }
        
        var iter = _base.makeIterator()
        if let first = iter.next() {
            result.append(contentsOf: first)
            while let next = iter.next() {
                result.append(contentsOf: _separator)
                result.append(contentsOf: next)
            }
        }
        
        return result
    }
}

// 这里限制了, 其实是 Sequence 里面的 Element 也必须是 Sequence
// 这个到底有多少人使用啊. 太偏门的一个实现了. 
extension Sequence where Element: Sequence {
    /// Returns the concatenated elements of this sequence of sequences,
    /// inserting the given separator between each element.
    ///
    /// This example shows how an array of `[Int]` instances can be joined, using
    /// another `[Int]` instance as the separator:
    ///
    ///     let nestedNumbers = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    ///     let joined = nestedNumbers.joined(separator: [-1, -2])
    ///     print(Array(joined))
    ///     // Prints "[1, 2, 3, -1, -2, 4, 5, 6, -1, -2, 7, 8, 9]"
    ///
    /// - Parameter separator: A sequence to insert between each of this
    ///   sequence's elements.
    /// - Returns: The joined sequence of elements.
    public __consuming func joined<Separator: Sequence>(
        separator: Separator
    ) -> JoinedSequence<Self>
    where Separator.Element == Element.Element {
        return JoinedSequence(base: self, separator: separator)
    }
}
