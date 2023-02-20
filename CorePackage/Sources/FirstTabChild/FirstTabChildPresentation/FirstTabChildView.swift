import SwiftUI
import Architecture
import FirstTabChildInteraction

public struct FirstTabChildView: View {

    @ObservedObject private var viewStore: ViewStoreOf<FirstTabChild>

    public init(
        viewStore: ViewStoreOf<FirstTabChild>
    ) {
        self.viewStore = viewStore
        print("--\(Self.self) is inited")
    }
    
    public var body: some View {
        print("--\(Self.self) is rendered")
        return VStack {
            Text("First Tab Child").font(.title)
                .padding(.all)
            
            Text("Value: \(viewStore.state.someValue.description)")
                .padding(.all)
            
            Button(
                action: { viewStore.send(.toggleValue) },
                label: { Text("Toggle Value") }
            )
        }
    }
}
