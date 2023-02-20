import SwiftUI

public struct RootTabView: View {
    private let tab1: AnyView
    private let tab2: AnyView

    public init(tab1: AnyView, tab2: AnyView) {
        self.tab1 = tab1
        self.tab2 = tab2
    }
    
    public var body: some View {
        TabView {
            tab1
            tab2
        }
    }
}
