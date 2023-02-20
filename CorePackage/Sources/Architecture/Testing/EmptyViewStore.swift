import Foundation

public extension ViewStore where ViewState: Equatable {
    static func empty(with initState: ViewState) -> Self {
        Self.init(.init(initialState: initState, reducer: EmptyReducer()))
    }
}

private struct EmptyReducer<State, Action>: ReducerProtocol {
    var body: some ReducerProtocol<State, Action> {
        Reduce { _, _ in  .none }
    }
}
