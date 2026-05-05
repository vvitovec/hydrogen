import XCTest

final class HydrogenUITests: XCTestCase {
    func testLaunchShowsSearchField() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.textFields["AddressField"].waitForExistence(timeout: 5))
    }
}
