import XCTest
@testable import Regex

class RegexMatcherTests: XCTestCase {
    func test_init_throws_RegexError_when_invalid_pattern_is_given() throws {
        do {
            _ = try RegexMatcher(pattern: "\\d+-(\\d+)?)-\\d+", options: .default)
            XCTFail("RegexError expected")
        } catch RegexError.parseError(let line, let offset) {
            XCTAssertEqual(1, line)
            XCTAssertEqual(11, offset)
        }
    }

    func test_init_returns_RegexMatcher_when_correct_pattern_is_given() throws {
        _ = try RegexMatcher(pattern: "\\d+-(\\d+)?-\\d+", options: .default)
    }

    func test_find_returns_false_when_iteration_is_finished() throws {
        let matcher = try RegexMatcher(pattern: "\\d+-(\\d+)?-\\d+", options: .default)
        try matcher.reset("a00-11-22b11-22-33c22-33-44d")
        XCTAssertTrue(try matcher.find())
        XCTAssertTrue(try matcher.find())
        XCTAssertTrue(try matcher.find())
        XCTAssertFalse(try matcher.find())
    }

    func test_hitEnd_returns_true_when_iteration_is_finished() throws {
        let matcher = try RegexMatcher(pattern: "\\d+-(\\d+)?-\\d+", options: .default)
        try matcher.reset("a00-11-22b11-22-33c22-33-44d")
        XCTAssertFalse(try matcher.hitEnd())
        _ = try matcher.find()
        XCTAssertFalse(try matcher.hitEnd())
        _ = try matcher.find()
        XCTAssertFalse(try matcher.hitEnd())
        _ = try matcher.find()
        XCTAssertFalse(try matcher.hitEnd())
        _ = try matcher.find()
        XCTAssertTrue(try matcher.hitEnd())
    }

    func test_appendReplacement() throws {
        let matcher = try RegexMatcher(pattern: "[abc]*?", options: .default)
        try matcher.reset("abc")
//        print(try matcher.matches())
//        print(try matcher.find())
//        _ = try matcher.find()
//        print(try matcher.groupCount())
//        print(try matcher.start(group: 1))
//        _ = try matcher.find()
//        print(try matcher.groupCount())
//        print(try matcher.start(group: 1))
    }
}
