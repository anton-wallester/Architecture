import Foundation

internal final class TestReducer<State, Action>: ReducerProtocol {
    let base: Reduce<State, Action>
    let effectDidSubscribe = AsyncStream<Void>.streamWithContinuation()
    var inFlightEffects: Set<LongLivingEffect> = []
    var receivedActions: [(action: Action, state: State)] = []
    var state: State
    
    init(_ base: Reduce<State, Action>, initialState: State) {
        self.base = base
        self.state = initialState
    }
    
    func reduce(into state: inout State, action: TestAction) -> EffectPublisher<TestAction> {
        let reducer = self.base
        
        let effects: EffectPublisher<Action>
        switch action.origin {
        case let .send(action):
            effects = reducer.reduce(into: &state, action: action)
            self.state = state
            
        case let .receive(action):
            effects = reducer.reduce(into: &state, action: action)
            self.receivedActions.append((action, state))
        }
        
        switch effects.operation {
        case .none:
            self.effectDidSubscribe.continuation.yield()
            return .none
            
        case .publisher:
            let effect = LongLivingEffect(action: action)
            return effects
                .handleEvents(
                    receiveSubscription: { [effectDidSubscribe, weak self] _ in
                        self?.inFlightEffects.insert(effect)
                        Task {
                            await Task.megaYield()
                            effectDidSubscribe.continuation.yield()
                        }
                    },
                    receiveCompletion: { [weak self] _ in self?.inFlightEffects.remove(effect) },
                    receiveCancel: { [weak self] in self?.inFlightEffects.remove(effect) }
                )
                .map { .init(origin: .receive($0), file: action.file, line: action.line) }
                .eraseToEffect()
        }
    }
    
    struct LongLivingEffect: Hashable {
        let id = UUID()
        let action: TestAction
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
    }
    
    struct TestAction {
        let origin: Origin
        let file: StaticString
        let line: UInt
        
        enum Origin {
            case receive(Action)
            case send(Action)
        }
    }
}
