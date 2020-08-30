import XCTest
@testable import Mastodon

final class MastodonTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Mastodon().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
