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

internal func repeated<T, R1, R2>(operation: @escaping (T, R1?) -> Promise<() throws -> R2>, convert: @escaping (R2) -> R1, interval: TimeInterval? = nil) -> ([T]) -> Promise<() throws -> [R2]> {
    return { values in
        _repeat(operation: operation, for: values[...], convert: convert, interval: interval)
    }
}

internal func repeated<T, R>(operation: @escaping (T) -> Promise<() throws -> R>, interval: TimeInterval? = nil) -> ([T]) -> Promise<() throws -> [R]> {
    return { values in
        _repeat(operation: { r, _ in operation(r) }, for: values[...], convert: { $0 }, interval: interval)
    }
}

private func _repeat<T, R1, R2>(operation: @escaping (T, R1?) -> Promise<() throws -> R2>, for values: ArraySlice<T>, convert: @escaping (R2) -> R1, interval: TimeInterval?, results: [R2] = []) -> Promise<() throws -> [R2]> {
    let (headOrNil, tail) = values.headAndTail
    guard let head = headOrNil else {
        return Promise { results }
    }
    
    let resultPromise: Promise<() throws -> R2>
    if let interval = interval, !tail.isEmpty {
        resultPromise = wait(operation(head, results.last.map(convert)), for: interval)
    } else {
        resultPromise = operation(head, results.last.map(convert))
    }
    
    return resultPromise.flatMap { getResult in
        _repeat(operation: operation, for: tail, convert: convert, interval: interval, results: results + [try getResult()])
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
