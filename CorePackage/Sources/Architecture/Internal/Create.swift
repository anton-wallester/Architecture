import Combine
import Darwin

internal final class DemandBuffer<S: Subscriber>: @unchecked Sendable {
    private var buffer = [S.Input]()
    private let subscriber: S
    private var completion: Subscribers.Completion<S.Failure>?
    private var demandState = Demand()
    private let lock: os_unfair_lock_t
    
    init(subscriber: S) {
        self.subscriber = subscriber
        lock = os_unfair_lock_t.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }
    
    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }
    
    func buffer(value: S.Input) -> Subscribers.Demand {
        switch demandState.requested {
        case .unlimited:
            return subscriber.receive(value)
        default:
            buffer.append(value)
            return flush()
        }
    }
    
    func complete(completion: Subscribers.Completion<S.Failure>) {
        self.completion = completion
        _ = flush()
    }
    
    func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
        flush(adding: demand)
    }
    
    private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
        lock.sync {
            
            if let newDemand = newDemand {
                demandState.requested += newDemand
            }
            
            // If buffer isn't ready for flushing, return immediately
            guard demandState.requested > 0 || newDemand == Subscribers.Demand.none else { return .none }
            
            while !buffer.isEmpty && demandState.processed < demandState.requested {
                demandState.requested += subscriber.receive(buffer.remove(at: 0))
                demandState.processed += 1
            }
            
            if let completion = completion {
                // Completion event was already sent
                buffer = []
                demandState = .init()
                self.completion = nil
                subscriber.receive(completion: completion)
                return .none
            }
            
            let sentDemand = demandState.requested - demandState.sent
            demandState.sent += sentDemand
            return sentDemand
        }
    }
    
    struct Demand {
        var processed: Subscribers.Demand = .none
        var requested: Subscribers.Demand = .none
        var sent: Subscribers.Demand = .none
    }
}

extension AnyPublisher where Failure == Never {
    private init(_ callback: @escaping (EffectPublisher<Output>.Subscriber) -> Cancellable) {
        self = Publishers.Create(callback: callback).eraseToAnyPublisher()
    }
    
    static func create(
        _ factory: @escaping (EffectPublisher<Output>.Subscriber) -> Cancellable
    ) -> AnyPublisher<Output, Never> {
        AnyPublisher(factory)
    }
}

extension Publishers  {
    fileprivate class Create<Output>: Publisher {
        typealias Failure = Never
        private let callback: (EffectPublisher<Output>.Subscriber) -> Cancellable
        
        init(callback: @escaping (EffectPublisher<Output>.Subscriber) -> Cancellable) {
            self.callback = callback
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Never {
            subscriber.receive(subscription: Subscription(callback: callback, downstream: subscriber))
        }
    }
}

extension Publishers.Create {
    fileprivate final class Subscription<Downstream: Subscriber>: Combine.Subscription
    where Downstream.Input == Output, Downstream.Failure == Never {
        private let buffer: DemandBuffer<Downstream>
        private var cancellable: Cancellable?
        
        init(
            callback: @escaping (EffectPublisher<Output>.Subscriber) -> Cancellable,
            downstream: Downstream
        ) {
            buffer = DemandBuffer(subscriber: downstream)
            
            let cancellable = callback(
                .init(
                    send: { [weak self] in _ = self?.buffer.buffer(value: $0) },
                    complete: { [weak self] in self?.buffer.complete(completion: $0) }
                )
            )
            
            self.cancellable = cancellable
        }
        
        func request(_ demand: Subscribers.Demand) {
            _ = buffer.demand(demand)
        }
        
        func cancel() {
            cancellable?.cancel()
        }
    }
}

extension EffectPublisher {
    struct Subscriber {
        private let _send: (Action) -> Void
        private let _complete: (Subscribers.Completion<Failure>) -> Void
        
        init(
            send: @escaping (Action) -> Void,
            complete: @escaping (Subscribers.Completion<Failure>) -> Void
        ) {
            _send = send
            _complete = complete
        }
        
        public func send(_ value: Action) {
            _send(value)
        }
        
        public func send(completion: Subscribers.Completion<Failure>) {
            _complete(completion)
        }
    }
}
