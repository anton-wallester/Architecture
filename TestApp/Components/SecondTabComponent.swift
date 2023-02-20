import Architecture
import Combine
import SecondTabInteraction
import SecondTabPresentation
import SwiftUI

struct SecondTabComponent {
    
    let parent: RootComponent
    
    let analytics: () -> Void
    let someDependency: () -> AnyPublisher<String, Never>
    
    init(parent: RootComponent) {
        self.parent = parent
        self.analytics = { print("--some event is recorded") }
        self.someDependency = {
            Just("result")
                .delay(for: 5, scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }
    
    func makeSecondTab() -> AnyView {
        let store: StoreOf<SecondTab> = .init(
            initialState: .init(),
            reducer: SecondTab(
                dependencies: .init(
                    logSomeEvent: analytics,
                    getSomeResult: someDependency
                )
            )
        )
         
        let viewStore = ViewStoreOf<SecondTab>(store, with: [.didStart])
        
        let view = SecondTabView(viewStore: viewStore)
        
        return AnyView(view)
    }
}
