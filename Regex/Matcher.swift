import Foundation
import Unicode

public final class Matcher: Cloneable {
    private let pattern: Pattern
    private var input: String
    private var unicode: [UniChar]
    public private(set) var region: Range<String.Index>
    private var previousEnd: String.Index

    init(pattern: Pattern, input: String) throws {
        self.pattern = pattern
        self.input = input
        self.unicode = Array(input.utf16)
        self.region = input.startIndex..<input.endIndex
        self.previousEnd = region.lowerBound

        var status = U_ZERO_ERROR
        uregex_setText(pattern.regexp, unicode, Int32(unicode.count), &status)
        try RegexError.throwIfNeeded(status: status)
    }

    /// Creates clone instance that has same input and region.
    public func clone() throws -> Matcher {
        let matcher = try Matcher(pattern: pattern.clone(), input: input)
        try matcher.set(region: region)
        return matcher
    }

    public func reset(_ input: String) throws {
        let unicode = Array(input.utf16)
        var status = U_ZERO_ERROR
        uregex_setText(pattern.regexp, unicode, Int32(unicode.count), &status)
        try RegexError.throwIfNeeded(status: status)
        self.input = input
        self.unicode = unicode
        self.region = input.startIndex..<input.endIndex
        resetEnd()
    }

    public func reset(index: String.Index) throws {
        var status = U_ZERO_ERROR
        uregex_reset(pattern.regexp, Int32(index.encodedOffset), &status)
        try RegexError.throwIfNeeded(status: status)
        resetEnd()
    }

    public func set(region: Range<String.Index>) throws {
        let regionStart = region.lowerBound
        let regionEnd = [region.upperBound, input.endIndex].min()!
        var status = U_ZERO_ERROR
        uregex_setRegion(pattern.regexp,
                         Int32(regionStart.encodedOffset),
                         Int32(regionEnd.encodedOffset),
                         &status)
        try RegexError.throwIfNeeded(status: status)
        self.region = regionStart..<regionEnd
        resetEnd()
    }

    public func hitEnd() throws -> Bool {
        var status = U_ZERO_ERROR
        let result = uregex_hitEnd(pattern.regexp, &status)
        try RegexError.throwIfNeeded(status: status)
        return result != 0
    }

    public func matches() throws -> Bool {
        resetEnd()
        var status = U_ZERO_ERROR
        let result = uregex_matches(pattern.regexp, -1, &status) != 0
        try RegexError.throwIfNeeded(status: status)
        return result
    }

    public func find() throws -> Bool {
        keepEnd()
        var status = U_ZERO_ERROR
        let result = uregex_findNext(pattern.regexp, &status) != 0
        try RegexError.throwIfNeeded(status: status)
        return result
    }

    public func find(start: String.Index) throws -> Bool {
        resetEnd()
        let start = [region.lowerBound, start].max()!
        var status = U_ZERO_ERROR
        let result = uregex_find(pattern.regexp, Int32(start.encodedOffset), &status) != 0
        try RegexError.throwIfNeeded(status: status)
        return result
    }

    public func start() throws -> String.Index {
        return try String.Index(encodedOffset: nativeStart())
    }

    public func start(group: Int) throws -> String.Index? {
        assert(group > 0, "Invalid group number: \(group)")
        let result = try nativeStart(group: group)
        return result == -1 ? nil : String.Index(encodedOffset: result)
    }

    public func end() throws -> String.Index {
        return try String.Index(encodedOffset: nativeEnd())
    }

    public func end(group: Int) throws -> String.Index? {
        assert(group > 0, "Invalid group number: \(group)")
        let result = try nativeEnd(group: group)
        return result == -1 ? nil : String.Index(encodedOffset: result)
    }

    public func append(replacement: String, to output: inout String) throws {
        try output.append(contentsOf: input[previousEnd..<start()])
        try appendFormatted(replacement: replacement, to: &output)
        keepEnd()
    }

    public func append(plainReplacement replacement: String, to output: inout String) throws {
        try output.append(contentsOf: input[previousEnd..<start()])
        output.append(contentsOf: replacement)
        keepEnd()
    }

    public func appendTail(to output: inout String) throws {
        output.append(contentsOf: input[previousEnd..<region.upperBound])
    }

    public func toMatch() throws -> Match {
        let range = try start()..<end()
        let groupRanges = try (0..<pattern.groupCount).map { index -> Range<String.Index>? in
            let group = index + 1
            guard let start = try self.start(group: group), let end = try self.end(group: group)
                else { return nil }
            return start..<end
        }
        return Match(pattern: pattern, input: input, range: range, groupRanges: groupRanges)
    }

    private func appendFormatted(replacement: String, to output: inout String) throws {
        var match: Match! = nil
        var index = replacement.startIndex
        while index < replacement.endIndex {
            let ch = replacement[index]
            index = replacement.index(after: index)

            switch ch.unicodeValue {
            case 0x5c: // '\'
                guard index < replacement.endIndex
                    else { break } // ignore last backslash
                output.append(replacement[index])
                index = replacement.index(after: index)
            case 0x24: // '$'
                guard index < replacement.endIndex
                    else { throw RegexError.regexInvalidCaptureGroupName }
                if match == nil {
                    match = try toMatch()
                }

                var isFirst = true
                var groupNumber = 0
                var c = replacement[index].unicodeValue
                if 0x30 <= c && c <= 0x39 { // digit
                    repeat {
                        let nextGroup = groupNumber * 10 + c - 0x30
                        if nextGroup > pattern.groupCount {
                            break
                        }
                        groupNumber = nextGroup
                        isFirst = false

                        index = replacement.index(after: index)
                        guard index < replacement.endIndex else { break }
                        c = replacement[index].unicodeValue
                    } while groupNumber <= pattern.groupCount && 0x30 <= c && c <= 0x39

                    guard !isFirst else { throw RegexError.regexInvalidCaptureGroupName }
                } else if c == 0x7b { // '{'
                    guard index < replacement.endIndex
                        else { throw RegexError.regexInvalidCaptureGroupName }
                    index = replacement.index(after: index)
                    let nameStart = index
                    var nameEnd: String.Index!
                    while true {
                        if index >= replacement.endIndex {
                            throw RegexError.regexInvalidCaptureGroupName
                        } else if replacement[index].unicodeValue == 0x7d {
                            nameEnd = index
                            index = replacement.index(after: index)
                            break
                        }

                        index = replacement.index(after: index)
                    }

                    let name = String(replacement[nameStart..<nameEnd])
                    guard !name.isEmpty else { throw RegexError.regexInvalidCaptureGroupName }
                    groupNumber = try pattern.getGroupNumber(from: name)
                } else {
                    throw RegexError.regexInvalidCaptureGroupName
                }

                if let group = match[groupNumber] {
                    output.append(String(group))
                }
            default:
                output.append(ch)
            }
        }
    }

    private func nativeStart(group: Int = 0) throws -> Int {
        var status = U_ZERO_ERROR
        let result = uregex_start(pattern.regexp, Int32(group), &status)
        try RegexError.throwIfNeeded(status: status)
        return Int(result)
    }

    private func keepEnd() {
        var status = U_ZERO_ERROR
        let previousEnd = Int(uregex_end(pattern.regexp, 0, &status))
        guard status == U_ZERO_ERROR
            else { return resetEnd() }
        self.previousEnd = String.Index(encodedOffset: previousEnd)
    }

    private func resetEnd() {
        self.previousEnd = region.lowerBound
    }

    private func nativeEnd(group: Int = 0) throws -> Int {
        var status = U_ZERO_ERROR
        let result = uregex_end(pattern.regexp, Int32(group), &status)
        try RegexError.throwIfNeeded(status: status)
        return Int(result)
    }
}

extension Character {
    fileprivate var unicodeValue: Int {
        guard unicodeScalars.count == 1 else { return -1 }
        return Int(unicodeScalars.first!.value)
    }
}

//
//    /// Replaces every substring of the input that matches the pattern with the given replacement string.
//    ///
//    /// - parameters:
//    ///     - replacement: a string containing the replacement text.
//    /// - returns: a string containing the results of the find and replace.
//    func replaceAll(with replacement: String) throws -> String {
//        let replacementChars = Array(replacement.utf16)
//        return try withBuffer(size: inputChars.count * 2) { buffer, size, status in
//            uregex_replaceAll(regexp, replacementChars, Int32(replacementChars.count), buffer, size, status)
//        }
//    }
//
//    /// Replaces the first substring of the input that matches the pattern with the replacement string.
//    ///
//    /// - parameters:
//    ///     - replacement: a string containing the replacement text.
//    /// - returns: a string in which the results are placed.
//    func replaceFirst(with replacement: String) throws -> String {
//        let replacementChars = Array(replacement.utf16)
//        return try withBuffer(size: inputChars.count * 2) { buffer, size, status in
//            uregex_replaceFirst(regexp, replacementChars, Int32(replacementChars.count), buffer, size, status)
//        }
//    }
//
//    /// Implements a replace operation intended to be used as part of an incremental find-and-replace.
//    ///
//    /// - parameters:
//    ///     - replacement: a string that provides the text to be substituted for the input text that matched the regexp pattern.
//    ///     - string: a string to which the results of the find-and-replace are appended.
//    func append(replacement: String, to string: inout String) throws {
//        let replacementChars = Array(replacement.utf16)
//        let result = try withBuffer { buffer, size, status in
//            var buffers: [UnsafeMutablePointer<UInt16>?] = [buffer]
//            var remaining = size
//            return uregex_appendReplacement(regexp, replacementChars, Int32(replacementChars.count), &buffers, &remaining, status)
//        }
//        string.append(result)
//    }
//
//    /// As the final step in a find-and-replace operation, append the remainder of the input string.
//    ///
//    /// - parameters:
//    ///     - string: a string to which the results of the find-and-replace are appended.
//    /// - returns: the destination string.
//    func appendTail(to string: inout String) throws {
//        let result = try withBuffer { buffer, size, status in
//            var buffers: [UnsafeMutablePointer<UInt16>?] = [buffer]
//            var remaining = size
//            return uregex_appendTail(regexp, &buffers, &remaining, status)
//        }
//        string.append(result)
//    }
//
//    private func withBuffer(size: Int = Int(BUFSIZ), callback: (UnsafeMutablePointer<UInt16>, Int32, UnsafeMutablePointer<UErrorCode>) throws -> Int32) throws -> String {
//        var buffer = Array<UInt16>(repeating: 0, count: size)
//        var status = U_ZERO_ERROR
//        let length = try callback(&buffer, Int32(buffer.count), &status)
//        if status == U_BUFFER_OVERFLOW_ERROR {
//            buffer = Array<UInt16>(repeating: 0, count: Int(length))
//            status = U_ZERO_ERROR
//            _ = try callback(&buffer, Int32(buffer.count), &status)
//        }
//        try RegexError.throwIfNeeded(status: status)
//        return String(utf16CodeUnits: buffer, count: Int(length))
//    }
//}
