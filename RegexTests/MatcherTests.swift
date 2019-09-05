import XCTest
@testable import Regex

class MatcherTests: XCTestCase {
    private let input = "𠀋𡈽𡌛𡑮𡢽𠮟𡚴𡸴𣇄𣗄𣜿𣝣𣳾𤟱𥒎𥔎𥝱𥧄𥶡𦫿𦹀𧃴𧚄𨉷𨏍𪆐𠂉"
    private lazy var region = String.Index(utf16Offset: 2, in: input)..<String.Index(utf16Offset: 50, in: input)
    private var matcher: Matcher!

    override func setUp() {
        self.matcher = try! Pattern("(?<capture>[𡌛𠮟𨉷𠂉])([𡑮𨏍])?", options: .default).createMatcher(for: input)
        try! matcher.set(region: region)
    }

    func test_setRegion_sets_region_of_matcher_input() throws {
        XCTAssertEqual(region, matcher.region)
    }

    func test_reset_resets_region() throws {
        let input = "リセット"
        try matcher.reset(input)
        XCTAssertEqual(String.Index(utf16Offset: 0, in: input)..<String.Index(utf16Offset: 4, in: input), matcher.region)
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
        XCTAssertEqual(String.Index(utf16Offset: 4, in: input)..<String.Index(utf16Offset: 8, in: input), match1.range)
        XCTAssertEqual(String.Index(utf16Offset: 4, in: input)..<String.Index(utf16Offset: 6, in: input), match1[1]?.range)
        XCTAssertEqual(String.Index(utf16Offset: 6, in: input)..<String.Index(utf16Offset: 8, in: input), match1[2]?.range)

        _ = try matcher.find()
        let match2 = try matcher.toMatch()
        XCTAssertEqual(String.Index(utf16Offset: 10, in: input)..<String.Index(utf16Offset: 12, in: input), match2.range)
        XCTAssertEqual(String.Index(utf16Offset: 10, in: input)..<String.Index(utf16Offset: 12, in: input), match2[1]?.range)
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
