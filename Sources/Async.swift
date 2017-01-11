internal func repeated<T, R>(operation: @escaping (T, @escaping (() throws -> R) -> ()) -> ()) -> ([T], @escaping (() throws -> [R]) -> ()) -> () {
    return { values, callback in
        _repeat(operation: operation, for: values[0..<values.count], callback: callback)
    }
}

private func _repeat<T, R>(operation: @escaping (T, @escaping (() throws -> R) -> ()) -> (), for values: ArraySlice<T>, results: [R] = [], callback: @escaping (() throws -> [R]) -> ()) {
    let (headOrNil, tail) = values.headAndTail
    guard let head = headOrNil else {
        callback { results }
        return
    }
    operation(head) { result in
        do {
            _repeat(operation: operation, for: tail, results: results + [try result()], callback: callback)
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
