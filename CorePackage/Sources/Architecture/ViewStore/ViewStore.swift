import Combine
import SwiftUI

public final class ViewStore<ViewState, ViewAction>: ObservableObject {
  // N.B. `ViewStore` does not use a `@Published` property, so `objectWillChange`
  // won't be synthesized automatically. To work around issues on iOS 13 we explicitly declare it.
  public private(set) lazy var objectWillChange = ObservableObjectPublisher()

  public var state: ViewState { self._state.value }
    
  private let _send: (ViewAction) -> Task<Void, Never>?
  fileprivate let _state: CurrentValueRelay<ViewState>
  private var viewCancellable: AnyCancellable?

  public init(_ store: Store<ViewState, ViewAction>) {
    self._send = { store.send($0) }
    self._state = CurrentValueRelay(store.state.value)
    self.viewCancellable = store.state
      .sink { [weak objectWillChange = self.objectWillChange, weak _state = self._state] in
        guard let objectWillChange = objectWillChange, let _state = _state else { return }
        objectWillChange.send()
        _state.value = $0
      }
  }
    
  @discardableResult
  public func send(_ action: ViewAction) -> ViewStoreTask {
    .init(rawValue: _send(action))
  }
}

public typealias ViewStoreOf<R: ReducerProtocol> = ViewStore<R.State, R.Action>

public struct ViewStoreTask: Hashable, Sendable {
  fileprivate let rawValue: Task<Void, Never>?

  public var isCancelled: Bool {
    self.rawValue?.isCancelled ?? true
  }
}
