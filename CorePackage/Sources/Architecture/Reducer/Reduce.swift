public struct Reduce<State, Action>: ReducerProtocol {
    
    let reduce: (inout State, Action) -> EffectPublisher<Action>
    
    public init(_ reduce: @escaping (inout State, Action) -> EffectPublisher<Action>) {
        self.reduce = reduce
    }
    
    public init<R: ReducerProtocol>(_ reducer: R) where R.State == State, R.Action == Action {
        self.reduce = reducer.reduce
    }
    
    public func reduce(into state: inout State, action: Action) -> EffectPublisher<Action> {
        self.reduce(&state, action)
    }
}

extension ReducerProtocol where Body == Never {
    public var body: Body {
        fatalError("\(Self.self)' has no body")
    }
}
