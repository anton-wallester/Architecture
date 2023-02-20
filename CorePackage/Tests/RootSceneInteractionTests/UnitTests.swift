import XCTest
@testable import FirstTabParentInteraction
import Architecture

class Tests: XCTestCase {
    
    func test_unit_test() {
    
        let store = TestStore(
            initialState: .init(),
            reducer: FirstTabParent(
                dependencies: .init(
                    getRandomNumber: { 5 },
                    routeToDirection: { _ in }
                )
            )
        )
        
        store.send(.updateRandomNumber) { state in
            state.randomNumber = 5
        }
    }
    
}
