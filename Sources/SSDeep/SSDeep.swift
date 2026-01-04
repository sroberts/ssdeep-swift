import Foundation

/// SSDeep fuzzy hashing library
///
/// SSDeep implements context-triggered piecewise hashing (CTPH), producing
/// similar hashes for similar inputs. This enables similarity detection
/// between files and data.
///
/// ## Basic Usage
///
/// ```swift
/// import SSDeep
///
/// // Hash a string
/// let hash = try SSDeep.hash("Hello, World!")
///
/// // Hash data
/// let data = Data([0x01, 0x02, 0x03])
/// let dataHash = try SSDeep.hash(data)
///
/// // Compare hashes
/// let similarity = SSDeep.compare(hash1, hash2)
/// print("Similarity: \(similarity)%")
/// ```
///
/// ## Streaming API
///
/// For large files, use the streaming API:
/// ```swift
/// let generator = SSDeepGenerator()
/// generator.setTotalLength(fileSize)
///
/// while let chunk = readNextChunk() {
///     generator.update(chunk)
/// }
///
/// let hash = try generator.finalize()
/// ```
public enum SSDeep {

    // MARK: - Hash Generation

    /// Compute fuzzy hash of data
    /// - Parameters:
    ///   - data: The data to hash
    ///   - options: Options for hash generation
    /// - Returns: The computed SSDeep hash
    /// - Throws: `SSDeepError.inputTooSmall` if input is too small
    public static func hash(_ data: Data, options: SSDeepOptions = []) throws -> SSDeepHash {
        let generator = SSDeepGenerator()
        generator.setTotalLength(UInt64(data.count))
        generator.update(data)
        return try generator.finalize(options: options)
    }

    /// Compute fuzzy hash of bytes
    /// - Parameters:
    ///   - bytes: The bytes to hash
    ///   - options: Options for hash generation
    /// - Returns: The computed SSDeep hash
    /// - Throws: `SSDeepError.inputTooSmall` if input is too small
    public static func hash(_ bytes: [UInt8], options: SSDeepOptions = []) throws -> SSDeepHash {
        let generator = SSDeepGenerator()
        generator.setTotalLength(UInt64(bytes.count))
        generator.update(bytes)
        return try generator.finalize(options: options)
    }

    /// Compute fuzzy hash of a string (UTF-8 encoded)
    /// - Parameters:
    ///   - string: The string to hash
    ///   - options: Options for hash generation
    /// - Returns: The computed SSDeep hash
    /// - Throws: `SSDeepError.inputTooSmall` if input is too small
    public static func hash(_ string: String, options: SSDeepOptions = []) throws -> SSDeepHash {
        let data = Data(string.utf8)
        return try hash(data, options: options)
    }

    /// Compute fuzzy hash of a file at path
    /// - Parameters:
    ///   - path: Path to the file
    ///   - options: Options for hash generation
    /// - Returns: The computed SSDeep hash
    /// - Throws: `SSDeepError.fileNotFound` if file doesn't exist,
    ///           `SSDeepError.fileReadError` on read errors
    public static func hashFile(at path: String, options: SSDeepOptions = []) throws -> SSDeepHash {
        let url = URL(fileURLWithPath: path)
        return try hashFile(at: url, options: options)
    }

    /// Compute fuzzy hash of a file at URL
    /// - Parameters:
    ///   - url: URL of the file
    ///   - options: Options for hash generation
    /// - Returns: The computed SSDeep hash
    /// - Throws: `SSDeepError.fileNotFound` if file doesn't exist,
    ///           `SSDeepError.fileReadError` on read errors
    public static func hashFile(at url: URL, options: SSDeepOptions = []) throws -> SSDeepHash {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: url.path) else {
            throw SSDeepError.fileNotFound
        }

        do {
            // Get file size
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0

            let generator = SSDeepGenerator()
            generator.setTotalLength(fileSize)

            // Read file in chunks for memory efficiency
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }

            let chunkSize = 64 * 1024  // 64 KB chunks
            while true {
                let data = handle.readData(ofLength: chunkSize)
                if data.isEmpty { break }
                generator.update(data)
            }

            return try generator.finalize(options: options)
        } catch let error as SSDeepError {
            throw error
        } catch {
            throw SSDeepError.fileReadError(error.localizedDescription)
        }
    }

    // MARK: - Comparison

    /// Compare two SSDeep hashes
    ///
    /// Returns a similarity score from 0 to 100:
    /// - 0: No similarity (or incompatible block sizes)
    /// - 100: Identical hashes
    ///
    /// - Parameters:
    ///   - hash1: First hash to compare
    ///   - hash2: Second hash to compare
    /// - Returns: Similarity score (0-100)
    public static func compare(_ hash1: SSDeepHash, _ hash2: SSDeepHash) -> Int {
        // Check block size compatibility
        let bs1 = hash1.blockSize
        let bs2 = hash2.blockSize

        if bs1 == bs2 {
            // Same block size - compare both hash components
            let score1 = compareStrings(hash1.hash1, hash2.hash1, blockSize: bs1)
            let score2 = compareStrings(hash1.hash2, hash2.hash2, blockSize: bs1 * 2)
            return max(score1, score2)
        } else if bs1 == bs2 * 2 {
            // hash1's block size is double hash2's
            // Compare hash1.hash1 with hash2.hash2
            return compareStrings(hash1.hash1, hash2.hash2, blockSize: bs1)
        } else if bs2 == bs1 * 2 {
            // hash2's block size is double hash1's
            // Compare hash1.hash2 with hash2.hash1
            return compareStrings(hash1.hash2, hash2.hash1, blockSize: bs2)
        }

        // Incompatible block sizes
        return 0
    }

    /// Compare two hash strings
    ///
    /// - Parameters:
    ///   - hash1: First hash string
    ///   - hash2: Second hash string
    /// - Returns: Similarity score (0-100)
    /// - Throws: `SSDeepError.invalidHash` if either hash is invalid
    public static func compare(_ hash1: String, _ hash2: String) throws -> Int {
        let parsed1 = try SSDeepHash.parse(hash1)
        let parsed2 = try SSDeepHash.parse(hash2)
        return compare(parsed1, parsed2)
    }

    // MARK: - Parsing

    /// Parse an SSDeep hash string
    /// - Parameter hashString: The hash string to parse
    /// - Returns: The parsed SSDeepHash
    /// - Throws: `SSDeepError.invalidHash` if the format is invalid
    public static func parse(_ hashString: String) throws -> SSDeepHash {
        return try SSDeepHash.parse(hashString)
    }

    /// Validate an SSDeep hash string format
    /// - Parameter hashString: The hash string to validate
    /// - Returns: true if the format is valid
    public static func isValid(_ hashString: String) -> Bool {
        return SSDeepHash.isValid(hashString)
    }

    // MARK: - Private Comparison Helpers

    private static func compareStrings(_ s1: String, _ s2: String, blockSize: UInt32) -> Int {
        // Both strings must be non-empty
        guard !s1.isEmpty && !s2.isEmpty else {
            return 0
        }

        // Check for minimum common substring
        guard EditDistance.hasCommonSubstring(s1, s2, minLength: SSDeepConstants.minCommonSubstringLength) else {
            return 0
        }

        // Calculate weighted edit distance
        let distance = EditDistance.weightedEditDistance(s1, s2)

        // Scale to 0-100
        // The score formula from the original ssdeep
        let score = scoreFromDistance(distance, length1: s1.count, length2: s2.count, blockSize: blockSize)

        return max(0, min(100, score))
    }

    private static func scoreFromDistance(_ distance: Int, length1: Int, length2: Int, blockSize: UInt32) -> Int {
        // Based on the original ssdeep scoring algorithm
        let maxLen = max(length1, length2)

        guard maxLen > 0 else { return 0 }

        // Calculate score based on edit distance
        // Higher distance = lower score
        let score = 100 - (100 * distance) / (maxLen * EditDistance.substitutionCost)

        return score
    }
}

// MARK: - Async API

#if swift(>=5.5)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SSDeep {

    /// Async hash computation for files
    /// - Parameters:
    ///   - url: URL of the file
    ///   - options: Options for hash generation
    /// - Returns: The computed SSDeep hash
    public static func hashFile(at url: URL, options: SSDeepOptions = []) async throws -> SSDeepHash {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let hash = try self.hashFile(at: url, options: options) as SSDeepHash
                    continuation.resume(returning: hash)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
#endif
