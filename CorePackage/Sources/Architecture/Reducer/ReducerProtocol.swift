public protocol ReducerProtocol<State,Action> {
    associatedtype State
    associatedtype Action
    
    // NB: For Xcode to favor autocompleting `var body: Body` over `var body: Never` we must use a
    //     type alias.
    associatedtype _Body
    
    typealias Body = _Body
    
    func reduce(into state: inout State, action: Action) -> EffectPublisher<Action>
    
    @ReducerBuilder<State, Action>
    var body: Body { get }
}

extension ReducerProtocol where Body: ReducerProtocol, Body.State == State, Body.Action == Action {
    public func reduce(
        into state: inout Body.State, action: Body.Action
    ) -> EffectPublisher<Body.Action> {
        self.body.reduce(into: &state, action: action)
    }
}
