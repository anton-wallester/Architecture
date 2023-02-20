import Combine
import SwiftUI

public struct EffectPublisher<Action> {
    enum Operation {
        case none
        case publisher(AnyPublisher<Action, Never>)
    }
    
    let operation: Operation
    
    init(operation: Operation) {
        self.operation = operation
    }
}

extension EffectPublisher {
    public static var none: Self {
        Self(operation: .none)
    }
}
