public extension ViewStore where ViewState: Equatable {
    convenience init(
        _ store: Store<ViewState, ViewAction>,
        with prependEvents: [ViewAction]
    ) {
        self.init(store)
        prependEvents.forEach { self.send($0) }
    }
}
