import Architecture

public struct FirstTabParent: ReducerProtocol {
    
    public enum Routing: Equatable {
        case scene2
    }
    
    public struct State: Equatable {
        public var randomNumber: Int?
        
        public init() { }
    }
    
    public enum Action: Equatable {
        case updateRandomNumber
        case routing(Routing)
    }
    
    public struct Dependencies {
        let getRandomNumber: () -> Int
        let routeToDirection: (Routing) -> Void
        
        public init(
            getRandomNumber: @escaping () -> Int,
            routeToDirection: @escaping (Routing) -> Void
        ) {
            self.getRandomNumber = getRandomNumber
            self.routeToDirection = routeToDirection
        }
    }
    
    private let dependencies: Dependencies
    
    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            print("--\(Self.self)", "State: \(state)", "Action: \(action)")
            switch action {
            case let .routing(direction):
                dependencies.routeToDirection(direction)
                return .none
                
            case .updateRandomNumber:
                state.randomNumber = dependencies.getRandomNumber()
                return .none
            }
        }
    }
}
