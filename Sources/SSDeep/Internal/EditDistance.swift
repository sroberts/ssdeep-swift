/// Weighted edit distance implementation for SSDeep comparison
enum EditDistance {
    /// Cost for insertion operation
    static let insertionCost = 1

    /// Cost for deletion operation
    static let deletionCost = 1

    /// Cost for substitution operation
    static let substitutionCost = 3

    /// Cost for transposition operation
    static let transpositionCost = 5

    /// Calculate the weighted edit distance between two strings
    ///
    /// Uses a modified Levenshtein distance with weighted costs:
    /// - Insertion: 1
    /// - Deletion: 1
    /// - Substitution: 3
    /// - Transposition: 5
    ///
    /// - Parameters:
    ///   - s1: First string
    ///   - s2: Second string
    /// - Returns: The weighted edit distance
    static func weightedEditDistance(_ s1: String, _ s2: String) -> Int {
        let chars1 = Array(s1)
        let chars2 = Array(s2)
        let m = chars1.count
        let n = chars2.count

        // Handle empty strings
        if m == 0 { return n * deletionCost }
        if n == 0 { return m * insertionCost }

        // Create DP table
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        // Initialize base cases
        for i in 0...m {
            dp[i][0] = i * deletionCost
        }
        for j in 0...n {
            dp[0][j] = j * insertionCost
        }

        // Fill the DP table
        for i in 1...m {
            for j in 1...n {
                if chars1[i - 1] == chars2[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    let insert = dp[i][j - 1] + insertionCost
                    let delete = dp[i - 1][j] + deletionCost
                    let substitute = dp[i - 1][j - 1] + substitutionCost
                    dp[i][j] = min(insert, delete, substitute)
                }

                // Check for transposition
                if i > 1 && j > 1 &&
                    chars1[i - 1] == chars2[j - 2] &&
                    chars1[i - 2] == chars2[j - 1] {
                    dp[i][j] = min(dp[i][j], dp[i - 2][j - 2] + transpositionCost)
                }
            }
        }

        return dp[m][n]
    }

    /// Check if two strings have a common substring of at least the specified length
    ///
    /// - Parameters:
    ///   - s1: First string
    ///   - s2: Second string
    ///   - minLength: Minimum length of common substring (default: 7)
    /// - Returns: true if a common substring exists
    static func hasCommonSubstring(_ s1: String, _ s2: String, minLength: Int = SSDeepConstants.minCommonSubstringLength) -> Bool {
        guard s1.count >= minLength && s2.count >= minLength else {
            return false
        }

        let chars1 = Array(s1)
        let chars2 = Array(s2)

        // Use a rolling hash approach for efficiency
        for i in 0...(chars1.count - minLength) {
            let substring = String(chars1[i..<(i + minLength)])
            if s2.contains(substring) {
                return true
            }
        }

        return false
    }

    /// Eliminate sequences of more than 3 consecutive repeated characters
    ///
    /// This is used when the eliminateSequences option is enabled.
    ///
    /// - Parameter string: The input string
    /// - Returns: String with repeated sequences reduced
    static func eliminateSequences(_ string: String) -> String {
        guard !string.isEmpty else { return string }

        var result: [Character] = []
        var lastChar: Character?
        var count = 0

        for char in string {
            if char == lastChar {
                count += 1
                if count < 4 {
                    result.append(char)
                }
            } else {
                lastChar = char
                count = 1
                result.append(char)
            }
        }

        return String(result)
    }
}
