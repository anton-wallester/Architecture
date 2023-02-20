import Combine
import Foundation

extension EffectPublisher {
    public func cancellable(id: AnyHashable, cancelInFlight: Bool = false) -> Self {
        switch operation {
        case .none:
            return .none
            
        case let .publisher(publisher):
            return Self(
                operation: .publisher(
                    Deferred {
                        ()
                        -> Publishers.HandleEvents<
                            Publishers.PrefixUntilOutput<
                                AnyPublisher<Action, Failure>, PassthroughSubject<Void, Never>
                        >
                        > in
                        _cancellablesLock.lock()
                        defer { _cancellablesLock.unlock() }
                        
                        let id = _CancelToken(id: id)
                        if cancelInFlight {
                            _cancellationCancellables[id]?.forEach { $0.cancel() }
                        }
                        
                        let cancellationSubject = PassthroughSubject<Void, Never>()
                        
                        var cancellationCancellable: AnyCancellable!
                        cancellationCancellable = AnyCancellable {
                            _cancellablesLock.sync {
                                cancellationSubject.send(())
                                cancellationSubject.send(completion: .finished)
                                _cancellationCancellables[id]?.remove(cancellationCancellable)
                                if _cancellationCancellables[id]?.isEmpty == .some(true) {
                                    _cancellationCancellables[id] = nil
                                }
                            }
                        }
                        
                        return publisher.prefix(untilOutputFrom: cancellationSubject)
                            .handleEvents(
                                receiveSubscription: { _ in
                                    _ = _cancellablesLock.sync {
                                        _cancellationCancellables[id, default: []].insert(
                                            cancellationCancellable
                                        )
                                    }
                                },
                                receiveCompletion: { _ in cancellationCancellable.cancel() },
                                receiveCancel: cancellationCancellable.cancel
                            )
                    }
                        .eraseToAnyPublisher()
                )
            )
        }
    }
    
    public static func cancel(id: AnyHashable) -> Self {
        .fireAndForget {
            _cancellablesLock.sync {
                _cancellationCancellables[.init(id: id)]?.forEach { $0.cancel() }
            }
        }
    }
}

public struct _CancelToken: Hashable {
    let id: AnyHashable
    let discriminator: ObjectIdentifier
    
    public init(id: AnyHashable) {
        self.id = id
        self.discriminator = ObjectIdentifier(type(of: id.base))
    }
}

public var _cancellationCancellables: [_CancelToken: Set<AnyCancellable>] = [:]
public let _cancellablesLock = NSRecursiveLock()
