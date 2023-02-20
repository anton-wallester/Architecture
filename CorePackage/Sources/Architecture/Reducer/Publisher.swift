import Combine

extension EffectPublisher: Publisher {
    public typealias Output = Action
    public typealias Failure = Never
    
    
    public func receive<S: Combine.Subscriber>(
        subscriber: S
    ) where S.Input == Action, S.Failure == Never {
        self.publisher.subscribe(subscriber)
    }
    
    var publisher: AnyPublisher<Action, Never> {
        switch operation {
        case .none:
            return Empty().eraseToAnyPublisher()
            
        case let .publisher(publisher):
            return publisher
        }
    }
}

extension EffectPublisher {
    public init<P: Publisher>(_ publisher: P) where P.Output == Output, P.Failure == Never {
        operation = .publisher(publisher.eraseToAnyPublisher())
    }
    
    public static func fireAndForget(_ work: @escaping () throws -> Void) -> Self {
        // NB: Ideally we'd return a `Deferred` wrapping an `Empty(completeImmediately: true)`, but
        //     due to a bug in iOS 13.2 that publisher will never complete. The bug was fixed in
        //     iOS 13.3, but to remain compatible with iOS 13.2 and higher we need to do a little
        //     trickery to make sure the deferred publisher completes.
        Deferred { () -> Publishers.CompactMap<Result<Action?, Failure>.Publisher, Action> in
            try? work()
            return Just<Output?>(nil)
                .setFailureType(to: Failure.self)
                .compactMap { $0 }
        }
        .eraseToEffect()
    }
}

extension Publisher where Failure == Never {
    public func eraseToEffect() -> EffectPublisher<Output> {
        EffectPublisher(self)
    }
}
