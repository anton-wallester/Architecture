import Foundation
import Combine
import Architecture

public struct SecondTab: ReducerProtocol {
        
    public struct State: Equatable {
        public var isLoading = false
        public var result: String?

        public init() { }
    }
    
    public enum Action: Equatable {
        case didStart
        case didAction
        case updateResult(String)
    }
        
    public struct Dependencies {
        let logSomeEvent: () -> Void
        let getSomeResult: () -> AnyPublisher<String, Never>
        
        public init(
            logSomeEvent: @escaping () -> Void,
            getSomeResult: @escaping () -> AnyPublisher<String, Never>
        ) {
            self.logSomeEvent = logSomeEvent
            self.getSomeResult = getSomeResult
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
            case .updateResult(let result):
                state.isLoading = false
                state.result = result
                // makes some sync work and return .none
                return .fireAndForget {
                    dependencies.logSomeEvent()
                }
                
            case .didStart:
                state.isLoading = true
                // convert reactive chain into Action
                return dependencies.getSomeResult()
                    .map(Action.updateResult)
                    .eraseToEffect()
                    .cancellable(
                        id: 123, // uniq id for cancelling
                        cancelInFlight: true // automatic cancelling at new action started
                    )
                
            case .didAction:
                state.result = nil
                // continue with another action
                return Just(Action.didStart)
                    .eraseToEffect()
            }
        }
    }
}
