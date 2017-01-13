import Foundation

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

public func _sync<T, R>(operation: (@escaping (T, @escaping (() throws -> R) -> ()) -> ())) -> (T) throws -> R {
    return  { value in
        var resultValue: R!
        var resultError: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        operation(value) { getValue in
            defer {
                semaphore.signal()
            }
            do {
                resultValue = try getValue()
            } catch let error {
                resultError = error
            }
        }
        semaphore.wait()
        
        if let error = resultError {
            throw error
        }
        
        return resultValue
    }
}

internal func repeated<T, R>(operation: (@escaping (T, @escaping (() throws -> R) -> ()) -> ()), interval: TimeInterval? = nil) -> ([T], @escaping (() throws -> [R]) -> ()) -> () {
    return { values, callback in
        _repeat(operation: operation, for: values[0..<values.count], interval: interval, callback: callback)
    }
}

private func _repeat<T, R>(operation: @escaping (T, @escaping (() throws -> R) -> ()) -> (), for values: ArraySlice<T>, interval: TimeInterval?, results: [R] = [], callback: @escaping (() throws -> [R]) -> ()) {
    let (headOrNil, tail) = values.headAndTail
    guard let head = headOrNil else {
        callback { results }
        return
    }
    
    let waitingOperation: (T, @escaping (() throws -> R) -> ()) -> ()
    if let interval = interval, values.count > 1 {
        waitingOperation = waiting(operation: operation, with: interval)
    } else {
        waitingOperation = operation
    }
    
    waitingOperation(head) { result in
        do {
            _repeat(operation: operation, for: tail, interval: interval, results: results + [try result()], callback: callback)
        } catch let error {
            callback { throw error }
        }
    }
}

internal func flatten<T, U, R>(_ operation1: @escaping (T, @escaping (() throws -> U) -> ()) -> (), _ operation2: @escaping (U, @escaping (() throws -> R) -> ()) -> ()) -> (T, @escaping (() throws -> R) -> ()) -> () {
    return { value, callback in
        operation1(value) { getValue in
            do {
                let value = try getValue()
                operation2(value) { getValue in
                    callback {
                        try getValue()
                    }
                }
            } catch let error {
                callback {
                    throw error
                }
            }
        }
    }
}

internal func waiting<T, R>(operation: @escaping (T, @escaping (() throws -> R) -> ()) -> (), with interval: TimeInterval) -> (T, @escaping (() throws -> R) -> ()) -> () {
    let wait: ((), @escaping (() throws -> ()) -> ()) -> () = { _, completion in
        Async.waitQueue.asyncAfter(deadline: .now() + .milliseconds(Int(interval * 1000.0))) {
            completion {
                ()
            }
        }
    }
    return { value, completion in
        join(operation, wait)((value, ())) { getValue in
            completion {
                let (value, _) = try getValue()
                return value
            }
        }
    }
}

internal func join<T1, R1, T2, R2>(_ operation1: @escaping (T1, @escaping (() throws -> R1) -> ()) -> (), _ operation2: @escaping (T2, @escaping (() throws -> R2) -> ()) -> ()) -> ((T1, T2), @escaping (() throws -> (R1, R2)) -> ()) -> () {
    return  { values, completion in
        let (value1, value2) = values
        var result1: R1?
        var result2: R2?
        var hasThrownError = false
        
        operation1(value1) { getValue in
            do {
                let result = try getValue()
                Async.executionQueue.async {
                    guard let result2 = result2 else {
                        result1 = result
                        return
                    }
                    completion {
                        (result, result2)
                    }
                }
            } catch let error {
                Async.executionQueue.async {
                    if hasThrownError {
                        return
                    }
                    hasThrownError = true
                    completion {
                        throw error
                    }
                }
            }
        }
        
        operation2(value2) { getValue in
            do {
                let result = try getValue()
                Async.executionQueue.async {
                    guard let result1 = result1 else {
                        result2 = result
                        return
                    }
                    completion {
                        (result1, result)
                    }
                }
            } catch let error {
                Async.executionQueue.async {
                    if hasThrownError {
                        return
                    }
                    hasThrownError = true
                    completion {
                        throw error
                    }
                }
            }
        }
    }
}

internal struct Async {
    internal static let sessionQueue = OperationQueue()
    internal static let executionQueue = DispatchQueue(label: "TweetupKit")
    fileprivate static let waitQueue = DispatchQueue(label: "TweetupKit.wait")
}
