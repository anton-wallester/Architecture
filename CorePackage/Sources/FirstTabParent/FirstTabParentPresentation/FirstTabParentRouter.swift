import Architecture
import FirstTabParentInteraction
import SwiftUI

public final class FirstTabParentRouter: BaseRouter<FirstTabParent.Routing> {
        
    private let routeToNextView: () -> AnyView
    
    public init(routeToNextView: @escaping () -> AnyView) {
        self.routeToNextView = routeToNextView
        super.init()
    }
        
    public override func route(to direction: FirstTabParent.Routing) {
        switch direction {
        case .scene2:
            routers[direction] = routeToNextView()
        }
    }
    
}
