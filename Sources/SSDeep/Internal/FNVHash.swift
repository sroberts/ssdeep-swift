/// FNV-1 style hash implementation for SSDeep
///
/// SSDeep uses a partial FNV-1 hash, keeping only the lowest 6 bits
/// for Base64 encoding.
struct FNVHash {
    private var hash: UInt32 = SSDeepConstants.hashInit

    /// Update the hash with a new byte
    /// - Parameter byte: The byte to add to the hash
    @inline(__always)
    mutating func update(_ byte: UInt8) {
        hash = (hash &* SSDeepConstants.fnvPrime) ^ UInt32(byte)
    }

    /// Get the final digest value (lower 6 bits for Base64 encoding)
    /// - Returns: A value 0-63 suitable for Base64 encoding
    @inline(__always)
    func digest() -> UInt8 {
        return UInt8(hash & 0x3F)
    }

    /// Get the full hash value (for testing/debugging)
    var fullHash: UInt32 {
        return hash
    }

    /// Reset the hash to its initial state
    mutating func reset() {
        hash = SSDeepConstants.hashInit
    }
}
