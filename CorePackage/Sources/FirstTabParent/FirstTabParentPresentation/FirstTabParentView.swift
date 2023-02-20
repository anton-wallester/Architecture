import Architecture
import FirstTabParentInteraction
import SwiftUI

public struct FirstTabParentView: View {
    
    @ObservedObject private var viewStore: ViewStoreOf<FirstTabParent>
    @ObservedObject private var router: BaseRouter<FirstTabParent.Routing>
    
    public init(
        viewStore: ViewStoreOf<FirstTabParent>,
        router: BaseRouter<FirstTabParent.Routing>
    ) {
        self.viewStore = viewStore
        self.router = router
        print("--\(Self.self) is inited")
    }

    public var body: some View {
        print("--\(Self.self) is rendered")
        return NavigationView {
            VStack {
                Text("First Tab Parent")
                    .font(.title)
                
                Text(viewStore.state.randomNumber.formatted)
                    .padding(.all)
                
                Button("Update number") {
                    viewStore.send(.updateRandomNumber)
                }.padding(.all)
                
                NavigationLink(
                    destination: router.view(for: .scene2),
                    isActive: router.binding(for: .scene2)
                ) {
                    Text("Go to the next screen").padding(.all)
                }
            }
        }
        .tabItem { Label("First", systemImage: "star") }
    }
}

private extension Optional where Wrapped == Int {
    var formatted: String {
        map { "\($0)" } ?? "<no value>"
    }
}
