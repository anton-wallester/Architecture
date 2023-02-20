import Architecture

public struct FirstTabChild: ReducerProtocol, Sendable {
 
    public struct State: Equatable {
        public var someValue: Bool = false
        
        public init() { }
    }
    
    public enum Action: Equatable {
        case toggleValue
    }
    
    public init() { }
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            print("--\(Self.self)", "State: \(state)", "Action: \(action)")
            switch action {
            case .toggleValue:
                state.someValue.toggle()
                return .none
            }
        }
    }
}
