import SwiftUI

open class BaseRouter<Direction: Hashable>: ObservableObject {
    
    @Published public var routers: [Direction: AnyView] = [:]
       
    public init() { }
    
    open func route(to direction: Direction) {
        fatalError("Not implemented")
    }
    
    public func back(from direction: Direction) {
        routers[direction] = nil
    }

    public func view(for direction: Direction) -> AnyView {
        routers[direction] ?? AnyView(EmptyView())
    }
}

public extension BaseRouter {
    func binding(for direction: Direction) -> Binding<Bool> {
        .init(
            get: { self.routers.keys.contains(direction) },
            set: { $0 ? self.route(to: direction) : self.back(from: direction) }
        )
    }
}
