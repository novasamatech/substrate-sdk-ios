import Foundation
import BigInt

@propertyWrapper
public struct Atomic<Value> {
    private let lock = NSLock()
    private var value: Value

    public init(defaultValue: Value) {
        value = defaultValue
    }

    public var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            value = newValue
            lock.unlock()
        }
    }
}
