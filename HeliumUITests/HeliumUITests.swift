import XCTest

final class HeliumUITests: XCTestCase {
    func testLaunchShowsSearchField() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.textFields["Search or website"].waitForExistence(timeout: 5))
    }
}
