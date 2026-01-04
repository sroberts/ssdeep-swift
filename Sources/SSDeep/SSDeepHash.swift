import Foundation

/// Represents a parsed SSDeep fuzzy hash
///
/// SSDeep hashes follow the format: `blocksize:hash1:hash2`
/// - `blocksize`: Integer representing the block size used
/// - `hash1`: Base64-encoded signature for the primary block size (max 64 chars)
/// - `hash2`: Base64-encoded signature for double the block size (max 64 chars)
public struct SSDeepHash: Hashable, Sendable {
    /// The block size used to generate the hash
    public let blockSize: UInt32

    /// The primary hash component (for the block size)
    public let hash1: String

    /// The secondary hash component (for double the block size)
    public let hash2: String

    /// Create a new SSDeepHash
    /// - Parameters:
    ///   - blockSize: The block size used
    ///   - hash1: The primary hash component
    ///   - hash2: The secondary hash component
    public init(blockSize: UInt32, hash1: String, hash2: String) {
        self.blockSize = blockSize
        self.hash1 = hash1
        self.hash2 = hash2
    }

    /// Parse an SSDeep hash from a string
    /// - Parameter string: The hash string in format "blocksize:hash1:hash2"
    /// - Throws: `SSDeepError.invalidHash` if the format is invalid
    /// - Returns: A parsed SSDeepHash
    public static func parse(_ string: String) throws -> SSDeepHash {
        let components = string.split(separator: ":", omittingEmptySubsequences: false)

        guard components.count == 3 else {
            throw SSDeepError.invalidHash
        }

        guard let blockSize = UInt32(components[0]) else {
            throw SSDeepError.invalidHash
        }

        guard blockSize >= SSDeepConstants.minBlockSize else {
            throw SSDeepError.invalidBlockSize
        }

        let hash1 = String(components[1])
        let hash2 = String(components[2])

        // Validate hash components contain only valid Base64 characters
        guard SSDeepBase64.isValidString(hash1) else {
            throw SSDeepError.invalidHash
        }
        guard SSDeepBase64.isValidString(hash2) else {
            throw SSDeepError.invalidHash
        }

        // Validate hash lengths
        guard hash1.count <= SSDeepConstants.spamsumLength else {
            throw SSDeepError.invalidHash
        }
        guard hash2.count <= SSDeepConstants.spamsumLength else {
            throw SSDeepError.invalidHash
        }

        return SSDeepHash(blockSize: blockSize, hash1: hash1, hash2: hash2)
    }

    /// Validate an SSDeep hash string format without throwing
    /// - Parameter string: The hash string to validate
    /// - Returns: true if the format is valid
    public static func isValid(_ string: String) -> Bool {
        return (try? parse(string)) != nil
    }
}

extension SSDeepHash: CustomStringConvertible {
    public var description: String {
        return "\(blockSize):\(hash1):\(hash2)"
    }
}

extension SSDeepHash: Codable {
    enum CodingKeys: String, CodingKey {
        case blockSize
        case hash1
        case hash2
    }

    public init(from decoder: Decoder) throws {
        // Try to decode from a simple string first
        if let container = try? decoder.singleValueContainer(),
           let hashString = try? container.decode(String.self) {
            self = try SSDeepHash.parse(hashString)
            return
        }

        // Fall back to keyed container
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blockSize = try container.decode(UInt32.self, forKey: .blockSize)
        hash1 = try container.decode(String.self, forKey: .hash1)
        hash2 = try container.decode(String.self, forKey: .hash2)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension SSDeepHash: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let hash = try? SSDeepHash.parse(description) else {
            return nil
        }
        self = hash
    }
}
