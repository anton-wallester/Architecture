import Combine
import CustomDump
import Foundation
import XCTestDynamicOverlay

public final class TestStore<State, Action, ScopedState, ScopedAction, Environment> {
    
    public var state: State { reducer.state }
    public var timeout: UInt64
    
    private let file: StaticString
    private let fromScopedAction: (ScopedAction) -> Action
    private var line: UInt
    let reducer: TestReducer<State, Action>
    private let store: Store<State, TestReducer<State, Action>.TestAction>
    private let toScopedState: (State) -> ScopedState
    
    public convenience init<R: ReducerProtocol>(
        initialState: @autoclosure () -> State,
        reducer: R,
        file: StaticString = #file,
        line: UInt = #line
    ) where
    R.State == State,
    R.Action == Action,
    State == ScopedState, State: Equatable,
    Action == ScopedAction,
    Environment == Void {
        self.init(
            initialState: initialState(),
            reducer: reducer,
            observe: { $0 },
            send: { $0 },
            file: file,
            line: line
        )
    }
    
    public init<R: ReducerProtocol>(
        initialState: @autoclosure () -> State,
        reducer: R,
        observe toScopedState: @escaping (State) -> ScopedState,
        send fromScopedAction: @escaping (ScopedAction) -> Action,
        file: StaticString = #file,
        line: UInt = #line
    ) where
    R.State == State,
    R.Action == Action,
    ScopedState: Equatable,
    Environment == Void {
        let initialState = initialState()
        let reducer = TestReducer(Reduce(reducer), initialState: initialState)
        self.file = file
        self.fromScopedAction = fromScopedAction
        self.line = line
        self.reducer = reducer
        self.store = Store(initialState: initialState, reducer: reducer)
        self.timeout = 100 * NSEC_PER_MSEC
        self.toScopedState = toScopedState
    }
}

extension TestStore where ScopedState: Equatable {
    
    @discardableResult
    public func send(
        _ action: ScopedAction,
        assert updateStateToExpectedResult: ((inout ScopedState) throws -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> TestStoreTask {
        if !self.reducer.receivedActions.isEmpty {
            var actions = ""
            customDump(reducer.receivedActions.map(\.action), to: &actions)
            XCTFail(
                """
                Must handle \(reducer.receivedActions.count) received \
                action\(reducer.receivedActions.count == 1 ? "" : "s") before sending an action: …
                
                Unhandled actions: \(actions)
                """,
                file: file,
                line: line
            )
        }
        
        let expectedState = toScopedState(state)
        let previousState = state
        let task = store.send(
            .init(origin: .send(fromScopedAction(action)), file: file, line: line)
        )
        
        do {
            let currentState = state
            reducer.state = previousState
            defer { reducer.state = currentState }
            
            try self.expectedStateShouldMatch(
                expected: expectedState,
                actual: toScopedState(currentState),
                updateStateToExpectedResult: updateStateToExpectedResult,
                file: file,
                line: line
            )
        } catch {
            XCTFail("Threw error: \(error)", file: file, line: line)
        }
        
        if "\(self.file)" == "\(file)" {
            self.line = line
        }
        
        return .init(rawValue: task, timeout: self.timeout)
    }
    
    private func expectedStateShouldMatch(
        expected: ScopedState,
        actual: ScopedState,
        updateStateToExpectedResult: ((inout ScopedState) throws -> Void)? = nil,
        file: StaticString,
        line: UInt
    ) throws {
        let current = expected
        var expected = expected
        
        var expectedWhenGivenPreviousState = expected
        if let updateStateToExpectedResult = updateStateToExpectedResult {
            try updateStateToExpectedResult(&expectedWhenGivenPreviousState)
        }
        expected = expectedWhenGivenPreviousState
        
        if expectedWhenGivenPreviousState != actual {
            expectationFailure(expected: expectedWhenGivenPreviousState)
        } else {
            tryUnnecessaryModifyFailure()
        }
        
        func expectationFailure(expected: ScopedState) {
            let difference =
            diff(expected, actual, format: .proportional)
                .map { "\($0.indent(by: 4))\n\n(Expected: −, Actual: +)" }
            ?? """
                Expected:
                \(String(describing: expected).indent(by: 2))
                
                Actual:
                \(String(describing: actual).indent(by: 2))
                """
            let messageHeading =
            updateStateToExpectedResult != nil
            ? "A state change does not match expectation"
            : "State was not expected to change, but a change occurred"
            XCTFail(
                """
                \(messageHeading): …
                
                \(difference)
                """,
                file: file,
                line: line
            )
        }
        
        func tryUnnecessaryModifyFailure() {
            guard expected == current && updateStateToExpectedResult != nil
            else { return }
            XCTFail("Expected state to change, but no change occurred", file: file, line: line)
        }
    }
}
