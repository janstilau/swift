@_silgen_name("swift_reflectionMirror_normalizedType")
internal func _getNormalizedType<T>(_: T, type: Any.Type) -> Any.Type

@_silgen_name("swift_reflectionMirror_count")
internal func _getChildCount<T>(_: T, type: Any.Type) -> Int

internal typealias NameFreeFunc = @convention(c) (UnsafePointer<CChar>?) -> Void

@_silgen_name("swift_reflectionMirror_subscript")
internal func _getChild<T>(
    of: T,
    type: Any.Type,
    index: Int,
    outName: UnsafeMutablePointer<UnsafePointer<CChar>?>,
    outFreeFunc: UnsafeMutablePointer<NameFreeFunc?>
) -> Any

// Returns 'c' (class), 'e' (enum), 's' (struct), 't' (tuple), or '\0' (none)
@_silgen_name("swift_reflectionMirror_displayStyle")
internal func _getDisplayStyle<T>(_: T) -> CChar

internal func getChild<T>(of value: T, type: Any.Type, index: Int) -> (label: String?, value: Any) {
    var nameC: UnsafePointer<CChar>? = nil
    var freeFunc: NameFreeFunc? = nil
    
    let value = _getChild(of: value, type: type, index: index, outName: &nameC, outFreeFunc: &freeFunc)
    
    let name = nameC.flatMap({ String(validatingUTF8: $0) })
    freeFunc?(nameC)
    return (name, value)
}

#if _runtime(_ObjC)
@_silgen_name("swift_reflectionMirror_quickLookObject")
internal func _getQuickLookObject<T>(_: T) -> AnyObject?

@_silgen_name("_swift_stdlib_NSObject_isKindOfClass")
internal func _isImpl(_ object: AnyObject, kindOf: AnyObject) -> Bool

internal func _is(_ object: AnyObject, kindOf `class`: String) -> Bool {
    return _isImpl(object, kindOf: `class` as AnyObject)
}

internal func _getClassPlaygroundQuickLook(
    _ object: AnyObject
) -> _PlaygroundQuickLook? {
    if _is(object, kindOf: "NSNumber") {
        let number: _NSNumber = unsafeBitCast(object, to: _NSNumber.self)
        switch UInt8(number.objCType[0]) {
        case UInt8(ascii: "d"):
            return .double(number.doubleValue)
        case UInt8(ascii: "f"):
            return .float(number.floatValue)
        case UInt8(ascii: "Q"):
            return .uInt(number.unsignedLongLongValue)
        default:
            return .int(number.longLongValue)
        }
    }
    
    if _is(object, kindOf: "NSAttributedString") {
        return .attributedString(object)
    }
    
    if _is(object, kindOf: "NSImage") ||
        _is(object, kindOf: "UIImage") ||
        _is(object, kindOf: "NSImageView") ||
        _is(object, kindOf: "UIImageView") ||
        _is(object, kindOf: "CIImage") ||
        _is(object, kindOf: "NSBitmapImageRep") {
        return .image(object)
    }
    
    if _is(object, kindOf: "NSColor") ||
        _is(object, kindOf: "UIColor") {
        return .color(object)
    }
    
    if _is(object, kindOf: "NSBezierPath") ||
        _is(object, kindOf: "UIBezierPath") {
        return .bezierPath(object)
    }
    
    if _is(object, kindOf: "NSString") {
        return .text(_forceBridgeFromObjectiveC(object, String.self))
    }
    
    return .none
}
#endif

// 这里是, Mirror 的构造方法
// 从处理的流程来看, 还是利用了元信息的数据, 在一个对象上, 根据元信息里面记录的成员变量的名字, 偏移量, 类型, 操作对象的数据.
// 因为 Swift 里面, 拷贝这个动作其实就是 bitCopy, 所以将数据复制出来, 除了引用计数需要考虑下, 其他的应该没有太大的危险.
// 本质上, 还是元信息编程的思路.
extension Mirror {
    internal init(internalReflecting subject: Any,
                  subjectType: Any.Type? = nil,
                  customAncestor: Mirror? = nil)
    {
        // _getNormalizedType 这个方法里面, 获取到这个对象的类型信息.
        let subjectType = subjectType ?? _getNormalizedType(subject, type: type(of: subject))
        
        // 根据类型信息, 可以获取到它的 child 的 Count 信息.
        let childCount = _getChildCount(subject, type: subjectType)
        // 这里, 从对象身上, 根据类型, 根据 idx, 取相应的 child 的数据.
        let children = (0 ..< childCount).lazy.map({
            getChild(of: subject, type: subjectType, index: $0)
        })
        self.children = Children(children)
        
        self._makeSuperclassMirror = {
            guard let subjectClass = subjectType as? AnyClass,
                  let superclass = _getSuperclass(subjectClass) else {
                return nil
            }
            
            // Handle custom ancestors. If we've hit the custom ancestor's subject type,
            // or descendants are suppressed, return it. Otherwise continue reflecting.
            if let customAncestor = customAncestor {
                if superclass == customAncestor.subjectType {
                    return customAncestor
                }
                if customAncestor._defaultDescendantRepresentation == .suppressed {
                    return customAncestor
                }
            }
            return Mirror(internalReflecting: subject,
                          subjectType: superclass,
                          customAncestor: customAncestor)
        }
        
        // 根据 对象, 取得它的 DisplayStyle 的信息.
        let rawDisplayStyle = _getDisplayStyle(subject)
        switch UnicodeScalar(Int(rawDisplayStyle)) {
        case "c": self.displayStyle = .class
        case "e": self.displayStyle = .enum
        case "s": self.displayStyle = .struct
        case "t": self.displayStyle = .tuple
        case "\0": self.displayStyle = nil
        default: preconditionFailure("Unknown raw display style '\(rawDisplayStyle)'")
        }
        
        self.subjectType = subjectType
        self._defaultDescendantRepresentation = .generated
    }
    
    internal static func quickLookObject(_ subject: Any) -> _PlaygroundQuickLook? {
        #if _runtime(_ObjC)
        let object = _getQuickLookObject(subject)
        return object.flatMap(_getClassPlaygroundQuickLook)
        #else
        return nil
        #endif
    }
}
