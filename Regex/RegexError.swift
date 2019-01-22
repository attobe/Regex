import Foundation
import Unicode

public enum RegexError: Error {
    case parseError(line: Int, offset: Int)
    case invalidState
    case indexOutbounds
    case regexInvalidState
    case regexInvalidCaptureGroupName
    case unknown(Int)

    private init(status: UErrorCode) {
        switch status {
        case U_INVALID_STATE_ERROR: self = .invalidState
        case U_INDEX_OUTOFBOUNDS_ERROR: self = .indexOutbounds
        case U_REGEX_INVALID_STATE: self = .regexInvalidState
        case U_REGEX_INVALID_CAPTURE_GROUP_NAME: self = .regexInvalidCaptureGroupName
        default: self = .unknown(Int(status.rawValue))
        }
    }

    static func throwIfNeeded(status: UErrorCode) throws {
        if status.rawValue <= U_ZERO_ERROR.rawValue {
            return
        }
        throw RegexError(status: status)
    }
}
