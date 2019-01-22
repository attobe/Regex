import XCTest
@testable import Regex

class PatternTests: XCTestCase {
    func test_init_throws_RegexError_when_invalid_pattern_is_given() throws {
        do {
            _ = try Pattern("\\d+-(\\d+)?)-\\d+", options: .default)
            XCTFail("RegexError expected")
        } catch RegexError.parseError(let line, let offset) {
            XCTAssertEqual(1, line)
            XCTAssertEqual(11, offset)
        }
    }

    func test_init_returns_RegexMatcher_when_correct_pattern_is_given() throws {
        _ = try Pattern("\\d+-(\\d+)?-\\d+", options: .default)
    }

    func test_groupCount_represents_correct_number_of_groups() throws {
        XCTAssertEqual(try Pattern("\\d+-\\d+-\\d+", options: .default).groupCount, 0)
        XCTAssertEqual(try Pattern("\\d+-(\\d+)-\\d+", options: .default).groupCount, 1)
        XCTAssertEqual(try Pattern("\\d+-(\\d+)-(\\d+)?", options: .default).groupCount, 2)
    }

    func test_getGroupNumberOf_returns_number_of_the_group() throws {
        XCTAssertEqual(try Pattern("\\d+-(?<mygroup>\\d+)-\\d+", options: .default).getGroupNumber(from: "mygroup"), 1)
    }

    func test_getGroupNumberOf_throws_RegexError_when_group_not_found() throws {
        do {
            _ = try Pattern("\\d+-(?<mygroup>\\d+)-\\d+", options: .default).getGroupNumber(from: "missing")
            XCTFail("RegexError expected")
        } catch RegexError.regexInvalidCaptureGroupName {
        }
    }

    func test_clone_does_not_throw_error() throws {
        _ = try Pattern("\\d+-\\d+-\\d+", options: .default).clone()
    }

    func test_createMatcher_returns_matcher_that_region_is_set_to_whole_text() throws {
        let input = "𠀋𡈽𡌛𡑮𡢽𠮟𡚴𡸴𣇄𣗄𣜿𣝣𣳾𤟱𥒎𥔎𥝱𥧄𥶡𦫿𦹀𧃴𧚄𨉷𨏍𪆐𠂉"
        let matcher = try Pattern("([𡌛𥧄𨏍𠂉])([𡑮𥶡])?", options: .default).createMatcher(for: input)
        XCTAssertEqual(matcher.region, input.startIndex..<input.endIndex)
    }
}
