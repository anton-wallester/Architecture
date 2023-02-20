import SwiftUI
import Architecture
import SecondTabInteraction

public struct SecondTabView: View {
    
    @ObservedObject private var viewStore: ViewStore<SecondTab.State, SecondTab.Action>
    
    public init(viewStore: ViewStore<SecondTab.State, SecondTab.Action>) {
        self.viewStore = viewStore
        print("--\(Self.self) is inited")
    }

    public var body: some View {
        print("--\(Self.self) is rendered")
        return VStack {
            if viewStore.state.isLoading {
                ProgressView()
            }
            Text("Second Tab").font(.title).padding(.all)
            Text(viewStore.state.result ?? "<no result>").padding(.all)
            Button("Retry") { viewStore.send(.didAction) }.padding(.all)
        }
        .tabItem { Label("Second", systemImage: "cross") }
    }
}
