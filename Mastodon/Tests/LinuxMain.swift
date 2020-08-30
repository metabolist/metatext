import XCTest

import MastodonTests

var tests = [XCTestCaseEntry]()
tests += MastodonTests.allTests()
XCTMain(tests)
