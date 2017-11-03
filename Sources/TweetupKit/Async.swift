import Foundation
import PromiseK

public func sync<T, R>(operation: (@escaping (T, @escaping (() throws -> R) -> ()) -> ())) -> (T) throws -> R {
    return  { value in
        var resultValue: R!
        var resultError: Error?
        var waiting = true
        
        operation(value) { getValue in
            defer {
                waiting = false
            }
            do {
                resultValue = try getValue()
            } catch let error {
                resultError = error
            }
        }
        let runLoop = RunLoop.current
        while waiting && runLoop.run(mode: .defaultRunLoopMode, before: .distantFuture) { }
        
        if let error = resultError {
            throw error
        }
        
        return resultValue
    }
}

internal func repeated<T, R>(operation: @escaping (T) -> Promise<() throws -> R>, interval: TimeInterval? = nil) -> ([T]) -> Promise<() throws -> [R]> {
    return { values in
        _repeat(operation: operation, for: values[...], interval: interval)
    }
}

private func _repeat<T, R>(operation: @escaping (T) -> Promise<() throws -> R>, for values: ArraySlice<T>, interval: TimeInterval?, results: [R] = []) -> Promise<() throws -> [R]> {
    let (headOrNil, tail) = values.headAndTail
    guard let head = headOrNil else {
        return Promise { results }
    }
    
    let resultPromise: Promise<() throws -> R>
    if let interval = interval, !tail.isEmpty {
        resultPromise = wait(operation(head), for: interval)
    } else {
        resultPromise = operation(head)
    }
    
    return resultPromise.flatMap { getResult in
        _repeat(operation: operation, for: tail, interval: interval, results: results + [try getResult()])
    }
}

internal func wait<T>(_ promise: Promise<() throws -> T>, for interval: TimeInterval) -> Promise<() throws -> T> {
    let waiting = Promise<()> { fulfill in
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(interval * 1000.0))) {
            fulfill(())
        }
    }
    return promise.flatMap { getValue in
        let value = try getValue()
        return waiting.map { _ in value }
    }
}
