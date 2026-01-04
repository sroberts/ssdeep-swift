import Foundation

/// Error types for SSDeep operations
public enum SSDeepError: Error, Equatable {
    /// Input data is too small to generate a meaningful hash
    case inputTooSmall

    /// Input data exceeds the maximum supported size
    case inputTooLarge

    /// The hash string format is invalid
    case invalidHash

    /// The block size in the hash is invalid
    case invalidBlockSize

    /// The two hashes have incompatible block sizes for comparison
    case incompatibleBlockSizes

    /// The specified file was not found
    case fileNotFound

    /// An error occurred while reading the file
    case fileReadError(String)

    public static func == (lhs: SSDeepError, rhs: SSDeepError) -> Bool {
        switch (lhs, rhs) {
        case (.inputTooSmall, .inputTooSmall),
             (.inputTooLarge, .inputTooLarge),
             (.invalidHash, .invalidHash),
             (.invalidBlockSize, .invalidBlockSize),
             (.incompatibleBlockSizes, .incompatibleBlockSizes),
             (.fileNotFound, .fileNotFound):
            return true
        case let (.fileReadError(msg1), .fileReadError(msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}

extension SSDeepError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .inputTooSmall:
            return "Input data is too small to generate a meaningful hash"
        case .inputTooLarge:
            return "Input data exceeds the maximum supported size"
        case .invalidHash:
            return "The hash string format is invalid"
        case .invalidBlockSize:
            return "The block size in the hash is invalid"
        case .incompatibleBlockSizes:
            return "The two hashes have incompatible block sizes for comparison"
        case .fileNotFound:
            return "The specified file was not found"
        case .fileReadError(let message):
            return "File read error: \(message)"
        }
    }
}
