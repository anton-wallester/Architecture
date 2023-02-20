@resultBuilder
public enum ReducerBuilder<State, Action> {
    
    public static func buildBlock<R: ReducerProtocol>(_ reducer: R) -> R
    where R.State == State, R.Action == Action {
        reducer
    }
    
    public static func buildExpression<R: ReducerProtocol>(_ expression: R) -> R
    where R.State == State, R.Action == Action {
        expression
    }
}
