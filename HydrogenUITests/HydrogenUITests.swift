import XCTest

final class HydrogenUITests: XCTestCase {
    func testLaunchShowsSearchField() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.textFields["Search or website"].waitForExistence(timeout: 5))
    }
}
