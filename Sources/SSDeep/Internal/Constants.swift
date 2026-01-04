/// Algorithm constants for SSDeep fuzzy hashing
enum SSDeepConstants {
    /// Maximum length of each hash component
    static let spamsumLength: Int = 64

    /// Maximum total result length (2 * 64 + 20 for blocksize and separators)
    static let fuzzyMaxResult: Int = 148

    /// Size of rolling hash window
    static let rollingWindow: Int = 7

    /// Minimum block size
    static let minBlockSize: UInt32 = 3

    /// Initial FNV hash value
    static let hashInit: UInt32 = 0x27  // 39

    /// FNV prime for hash computation
    static let fnvPrime: UInt32 = 0x01000193

    /// Maximum number of block hash levels
    static let numBlockHashes: Int = 31

    /// Minimum common substring length for comparison
    static let minCommonSubstringLength: Int = 7

    /// Base64-like alphabet used by SSDeep
    static let base64Alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

    /// Lookup table for reverse Base64 decoding (character to index)
    static let base64Lookup: [Character: UInt8] = {
        var lookup: [Character: UInt8] = [:]
        for (index, char) in base64Alphabet.enumerated() {
            lookup[char] = UInt8(index)
        }
        return lookup
    }()
}
