import Combine
import Foundation

public typealias StoreOf<R: ReducerProtocol> = Store<R.State, R.Action>

public final class Store<State, Action> {
    public var effectCancellables: [UUID: AnyCancellable] = [:]
    var parentCancellable: AnyCancellable?
    var state: CurrentValueSubject<State, Never>
    private var bufferedActions: [Action] = []
    private var isSending = false
    private let reducer: any ReducerProtocol<State, Action>
    
    public init<R: ReducerProtocol>(
        initialState: @autoclosure () -> R.State,
        reducer: R
    ) where R.State == State, R.Action == Action {
        self.state = CurrentValueSubject(initialState())
        self.reducer = reducer
    }
    
    public func send(
        _ action: Action,
        originatingFrom originatingAction: Action? = nil
    ) -> Task<Void, Never>? {
        bufferedActions.append(action)
        guard !self.isSending else { return nil }
        
        isSending = true
        var currentState = self.state.value
        let tasks = Box<[Task<Void, Never>]>(wrappedValue: [])
        defer {
            withExtendedLifetime(self.bufferedActions) {
                self.bufferedActions.removeAll()
            }
            self.state.value = currentState
            self.isSending = false
            if !self.bufferedActions.isEmpty {
                if let task = self.send(
                    self.bufferedActions.removeLast(), originatingFrom: originatingAction
                ) {
                    tasks.wrappedValue.append(task)
                }
            }
        }
        
        var index = self.bufferedActions.startIndex
        while index < self.bufferedActions.endIndex {
            defer { index += 1 }
            let action = self.bufferedActions[index]
            let effect = self.reducer.reduce(into: &currentState, action: action)
            
            switch effect.operation {
            case .none:
                break
                
            case let .publisher(publisher):
                var didComplete = false
                let boxedTask = Box<Task<Void, Never>?>(wrappedValue: nil)
                let uuid = UUID()
                let effectCancellable =
                publisher
                    .handleEvents(receiveCancel: { [weak self] in self?.effectCancellables[uuid] = nil })
                    .sink(
                        receiveCompletion: { [weak self] _ in
                            boxedTask.wrappedValue?.cancel()
                            didComplete = true
                            self?.effectCancellables[uuid] = nil
                        },
                        receiveValue: { [weak self] effectAction in
                            guard let self = self else { return }
                            if let task = self.send(effectAction, originatingFrom: action) {
                                tasks.wrappedValue.append(task)
                            }
                        }
                    )
                
                if !didComplete {
                    let task = Task<Void, Never> { @MainActor in
                        for await _ in AsyncStream<Void>.never {}
                        effectCancellable.cancel()
                    }
                    boxedTask.wrappedValue = task
                    tasks.wrappedValue.append(task)
                    self.effectCancellables[uuid] = effectCancellable
                }
            }
        }
        
        guard !tasks.wrappedValue.isEmpty else { return nil }
        return Task {
            await withTaskCancellationHandler {
                var index = tasks.wrappedValue.startIndex
                while index < tasks.wrappedValue.endIndex {
                    defer { index += 1 }
                    await tasks.wrappedValue[index].value
                }
            } onCancel: {
                var index = tasks.wrappedValue.startIndex
                while index < tasks.wrappedValue.endIndex {
                    defer { index += 1 }
                    tasks.wrappedValue[index].cancel()
                }
            }
        }
    }
}
