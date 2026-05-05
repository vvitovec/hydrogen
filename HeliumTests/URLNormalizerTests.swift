import XCTest
@testable import Helium

final class URLNormalizerTests: XCTestCase {
    func testPreservesFullHTTPSURL() {
        XCTAssertEqual(URLNormalizer.url(for: "https://example.com/path").absoluteString, "https://example.com/path")
    }

    func testAddsHTTPSForBareDomain() {
        XCTAssertEqual(URLNormalizer.url(for: "example.com").absoluteString, "https://example.com")
    }

    func testSearchesPlainText() {
        let url = URLNormalizer.url(for: "minimal browser")
        XCTAssertEqual(url.host(), "duckduckgo.com")
        XCTAssertTrue(url.absoluteString.contains("minimal%20browser"))
    }
}
