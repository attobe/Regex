import Foundation

final class ThreadLocal<T: Cloneable> {
    private let key: String
    private let object: T

    init(_ object: T) {
        self.key = "Regex.ThreadLocal.\(issueIdentifier())"
        self.object = object
        self.store(object)
    }

    func get() throws -> T {
        if let stored = Thread.current.threadDictionary[key] as? T {
            return stored
        }
        return try store(object.clone())
    }

    @discardableResult
    private func store(_ object: T) -> T {
        Thread.current.threadDictionary[key] = object
        return object
    }
}

private let lock = DispatchSemaphore(value: 1)
private var identifier = 0

private func issueIdentifier() -> Int {
    lock.wait()
    defer { lock.signal() }
    identifier += 1
    return identifier
}
