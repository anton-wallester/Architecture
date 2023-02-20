extension AsyncStream {
    /// > Warning: ⚠️ `AsyncStream` does not support multiple subscribers, therefore you can only use
    /// > this helper to test features that do not subscribe multiple times to the dependency
    /// > endpoint.
    ///
    /// - Parameters:
    ///   - elementType: The type of element the `AsyncStream` produces.
    ///   - limit: A Continuation.BufferingPolicy value to set the stream’s buffering behavior. By
    ///     default, the stream buffers an unlimited number of elements. You can also set the policy
    ///     to buffer a specified number of oldest or newest elements.
    /// - Returns: An `AsyncStream`.
    static func streamWithContinuation(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) -> (stream: Self, continuation: Continuation) {
        var continuation: Continuation!
        return (Self(elementType, bufferingPolicy: limit) { continuation = $0 }, continuation)
    }
    
    /// An `AsyncStream` that never emits and never completes unless cancelled.
    static var never: Self { Self { _ in } }
}
