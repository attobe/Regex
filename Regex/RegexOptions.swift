import Foundation
import Unicode

public struct RegexOptions: OptionSet {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Enable case insensitive matching.
    public static let caseInsensitive = RegexOptions(rawValue: UREGEX_CASE_INSENSITIVE.rawValue)

    /// Allow white space and comments within patterns.
    public static let comments = RegexOptions(rawValue: UREGEX_COMMENTS.rawValue)

    /// If set, '.' matches line terminators, otherwise '.' matching stops at line end.
    public static let dotall = RegexOptions(rawValue: UREGEX_DOTALL.rawValue)

    /// If set, treat the entire pattern as a literal string.
    /// Metacharacters or escape sequences in the input sequence will be given no special meaning.
    /// The flag UREGEX_CASE_INSENSITIVE retains its impact on matching when used in conjunction with this flag. The other flags become superfluous.
    public static let literal = RegexOptions(rawValue: UREGEX_LITERAL.rawValue)

    /// Control behavior of "$" and "^" If set, recognize line terminators within string, otherwise, match only at start and end of input string.
    public static let multiline = RegexOptions(rawValue: UREGEX_MULTILINE.rawValue)

    /// Unix-only line endings.
    /// When this mode is enabled, only \u000a is recognized as a line ending in the behavior of ., ^, and $.
    public static let unixLines = RegexOptions(rawValue: UREGEX_UNIX_LINES.rawValue)

    /// Unicode word boundaries.
    /// If set, uses the Unicode TR 29 definition of word boundaries. Warning: Unicode word boundaries are quite different from traditional regular expression word boundaries. See http://unicode.org/reports/tr29/#Word_Boundaries
    public static let uword = RegexOptions(rawValue: UREGEX_UWORD.rawValue)

    /// Error on Unrecognized backslash escapes.
    /// If set, fail with an error on patterns that contain backslash-escaped ASCII letters without a known special meaning. If this flag is not set, these escaped letters represent themselves.
    public static let errorOnUnknownEscapes = RegexOptions(rawValue: UREGEX_ERROR_ON_UNKNOWN_ESCAPES.rawValue)

    public static let `default` = errorOnUnknownEscapes
}
