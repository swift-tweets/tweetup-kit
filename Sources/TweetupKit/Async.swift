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
    
    let waitingOperation: (T) -> Promise<() throws -> R>
    if let interval = interval, values.count > 1 {
        waitingOperation = waiting(operation: operation, with: interval)
    } else {
        waitingOperation = operation
    }
    
    return waitingOperation(head).flatMap { result in
        _repeat(operation: operation, for: tail, interval: interval, results: results + [try result()])
    }
}

internal func waiting<T, R>(operation: @escaping (T) -> Promise<() throws -> R>, with interval: TimeInterval) -> (T) -> Promise<() throws -> R> {
    let wait: () -> Promise<() throws -> ()> = {
        Promise<() throws -> ()> { fulfill in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(interval * 1000.0))) {
                fulfill { () }
            }
        }
    }
    return { value in
        join(operation, wait)(value, ()).map { getValue in
            let (value, _) = try getValue()
            return value
        }
    }
}

internal func join<T1, R1, T2, R2>(_ operation1: @escaping (T1) -> Promise<() throws -> R1>, _ operation2: @escaping (T2) -> Promise<() throws -> R2>) -> (T1, T2) -> Promise<() throws -> (R1, R2)> {
    return  { value1, value2 in
        let promise1 = operation1(value1)
        let promise2 = operation2(value2)
        
        let results: Promise<() throws -> (R1, R2)> = promise1.flatMap { getResult1 throws -> Promise<() throws -> (R1, R2)> in
            let result1 = try getResult1()
            return promise2.map { getResult2 in
                ( result1, try getResult2())
            }
        }
        return results
    }
}
