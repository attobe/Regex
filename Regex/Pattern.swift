import Foundation
import Unicode

public final class Pattern: Cloneable {
    let regexp: OpaquePointer
    public let groupCount: Int

    public convenience init(_ regex: String, options: RegexOptions) throws {
        let unicode = Array(regex.utf16)
        var error = UParseError()
        var status = U_ZERO_ERROR
        let regexp = uregex_open(unicode, Int32(unicode.count), options.rawValue, &error, &status)
        if status.rawValue > U_ZERO_ERROR.rawValue {
            throw RegexError.parseError(line: Int(error.line), offset: Int(error.offset))
        }

        status = U_ZERO_ERROR
        let groupCount = Int(uregex_groupCount(regexp, &status))

        self.init(regexp: regexp!, groupCount: groupCount)
    }

    private init(regexp: OpaquePointer, groupCount: Int) {
        self.regexp = regexp
        self.groupCount = groupCount
    }

    public func getGroupNumber(from name: String) throws -> Int {
        let unicode = Array(name.utf16)
        var status = U_ZERO_ERROR
        let result = uregex_groupNumberFromName(regexp, unicode, Int32(unicode.count), &status)
        try RegexError.throwIfNeeded(status: status)
        return Int(result)
    }

    public func createMatcher(for input: String) throws -> Matcher {
        return try Matcher(pattern: clone(), input: input)
    }

    public func clone() throws -> Pattern {
        var status = U_ZERO_ERROR
        return Pattern(regexp: uregex_clone(regexp, &status), groupCount: groupCount)
    }

    deinit {
        uregex_close(regexp)
    }
}
