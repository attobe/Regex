import XCTest
@testable import Regex

class MatcherTests: XCTestCase {
    private let input = "𠀋𡈽𡌛𡑮𡢽𠮟𡚴𡸴𣇄𣗄𣜿𣝣𣳾𤟱𥒎𥔎𥝱𥧄𥶡𦫿𦹀𧃴𧚄𨉷𨏍𪆐𠂉"
    private let region = String.Index(encodedOffset: 2)..<String.Index(encodedOffset: 50)
    private var matcher: Matcher!

    override func setUp() {
        self.matcher = try! Pattern("(?<capture>[𡌛𠮟𨉷𠂉])([𡑮𨏍])?", options: .default).createMatcher(for: input)
        try! matcher.set(region: region)
    }

    func test_setRegion_sets_region_of_matcher_input() throws {
        XCTAssertEqual(region, matcher.region)
    }

    func test_reset_resets_region() throws {
        try matcher.reset("リセット")
        XCTAssertEqual(String.Index(encodedOffset: 0)..<String.Index(encodedOffset: 4), matcher.region)
    }

    func test_find_returns_true_on_matched() throws {
        XCTAssertTrue(try matcher.find())
        XCTAssertTrue(try matcher.find())
        XCTAssertTrue(try matcher.find())
    }

    func test_find_returns_false_on_matched() throws {
        _ = try matcher.find()
        _ = try matcher.find()
        _ = try matcher.find()
        XCTAssertFalse(try matcher.find())
        XCTAssertFalse(try matcher.find())
    }

    func test_toMatch_throws_RegexError_when_not_matched() throws {
        do {
            _ = try matcher.toMatch()
            XCTFail("expected: RegexError.regexInvalidState")
        } catch RegexError.regexInvalidState {
        }
        _ = try matcher.find()
        _ = try matcher.find()
        _ = try matcher.find()
        _ = try matcher.find()
        do {
            _ = try matcher.toMatch()
            XCTFail("expected: RegexError.regexInvalidState")
        } catch RegexError.regexInvalidState {
        }
    }

    func test_toMatch_returns_Match_that_has_correct_range() throws {
        _ = try matcher.find()
        let match1 = try matcher.toMatch()
        XCTAssertEqual(String.Index(encodedOffset: 4)..<String.Index(encodedOffset: 8), match1.range)
        XCTAssertEqual(String.Index(encodedOffset: 4)..<String.Index(encodedOffset: 6), match1[1]?.range)
        XCTAssertEqual(String.Index(encodedOffset: 6)..<String.Index(encodedOffset: 8), match1[2]?.range)

        _ = try matcher.find()
        let match2 = try matcher.toMatch()
        XCTAssertEqual(String.Index(encodedOffset: 10)..<String.Index(encodedOffset: 12), match2.range)
        XCTAssertEqual(String.Index(encodedOffset: 10)..<String.Index(encodedOffset: 12), match2[1]?.range)
        XCTAssertEqual(nil, match2[2]?.range)
    }

    func test_appendReplacement_appends_plain_text_after_previous_match() throws {
        var output = "オリジナル"
        _ = try matcher.find()
        try matcher.append(replacement: "リプレイス1", to: &output)
        XCTAssertEqual("オリジナル𡈽リプレイス1", output)

        _ = try matcher.find()
        try matcher.append(replacement: "リプレイス2", to: &output)
        XCTAssertEqual("オリジナル𡈽リプレイス1𡢽リプレイス2", output)
    }
}
