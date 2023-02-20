import SwiftUI
import RootTabPresentation

struct RootComponent {

    func makeRoot() -> AnyView {
        // No logic here, no point to use Architecture
        let view = RootTabView(
            tab1: makeTab1(),
            tab2: makeTab2()
        )
        return AnyView(view)
    }

    private func makeTab1() -> AnyView {
        FirstTabParentComponent(parent: self)
            .makeFirstTabParent()
    }

    private func makeTab2() -> AnyView {
        SecondTabComponent(parent: self)
            .makeSecondTab()
    }
}
