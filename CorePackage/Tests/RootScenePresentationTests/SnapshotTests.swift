import XCTest
import FirstTabParentInteraction
@testable import FirstTabParentPresentation
import Architecture
import SwiftUI

class SnapshotTests: XCTestCase {
    
    func test_snapshot_test() {
        let view = FirstTabParentView(
            viewStore: .empty(with: .init()),
            router: BaseRouter<FirstTabParent.Routing>()
        )
        
        // snapshot
        print(view)
    }
}
