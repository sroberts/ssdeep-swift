/// SSDeep-specific Base64 encoding utilities
enum SSDeepBase64 {
    /// Encode a 6-bit value (0-63) to a Base64 character
    /// - Parameter value: A value in the range 0-63
    /// - Returns: The corresponding Base64 character
    @inline(__always)
    static func encode(_ value: UInt8) -> Character {
        precondition(value < 64, "Value must be in range 0-63")
        return SSDeepConstants.base64Alphabet[Int(value)]
    }

    /// Decode a Base64 character to its 6-bit value
    /// - Parameter char: A Base64 character
    /// - Returns: The corresponding value (0-63), or nil if invalid
    @inline(__always)
    static func decode(_ char: Character) -> UInt8? {
        return SSDeepConstants.base64Lookup[char]
    }

    /// Check if a character is a valid SSDeep Base64 character
    /// - Parameter char: The character to check
    /// - Returns: true if the character is valid
    @inline(__always)
    static func isValid(_ char: Character) -> Bool {
        return SSDeepConstants.base64Lookup[char] != nil
    }

    /// Check if a string contains only valid SSDeep Base64 characters
    /// - Parameter string: The string to validate
    /// - Returns: true if all characters are valid Base64
    static func isValidString(_ string: String) -> Bool {
        return string.allSatisfy { isValid($0) }
    }
}
