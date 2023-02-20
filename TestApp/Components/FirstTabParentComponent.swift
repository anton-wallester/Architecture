import SwiftUI
import FirstTabParentInteraction
import FirstTabParentPresentation
import Architecture

struct FirstTabParentComponent {
    
    let parent: RootComponent
    let dependency: () -> Int = { Int.random(in: 100...999) }
    
    func makeFirstTabParent() -> AnyView {
        
        let router = FirstTabParentRouter(routeToNextView: makeChild)
        
        let store: Architecture.StoreOf<FirstTabParent> = .init(
            initialState: .init(),
            reducer: FirstTabParent(
                dependencies: .init(
                    getRandomNumber: dependency,
                    routeToDirection: router.route
                )
            )
        )
        
        let viewStore = ViewStore(store)
        
        let view = FirstTabParentView(viewStore: viewStore, router: router)
        
        return AnyView(view)
    }

    private func makeChild() -> AnyView {
        FirstTabChildComponent(parent: self).makeFirstTabChild()
    }
}
