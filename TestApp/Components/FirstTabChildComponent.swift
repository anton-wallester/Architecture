import SwiftUI
import FirstTabChildInteraction
import FirstTabChildPresentation
import Architecture

struct FirstTabChildComponent {
    
    let parent: FirstTabParentComponent
    
    func makeFirstTabChild() -> AnyView {
        let store = StoreOf<FirstTabChild>(initialState: .init(), reducer: FirstTabChild())
        
        let viewStore = ViewStore(store)
        
        let view = FirstTabChildView(viewStore: viewStore)
        
        return AnyView(view)
    }
}
