import Foundation

/// Options for SSDeep hash generation
public struct SSDeepOptions: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Eliminate sequences of more than 3 consecutive repeated characters
    public static let eliminateSequences = SSDeepOptions(rawValue: 1 << 0)

    /// Do not truncate the hash (not typically used, for compatibility)
    public static let noTruncate = SSDeepOptions(rawValue: 1 << 1)
}

/// State for a single block hash level
private struct BlockHashState {
    var fnvHash: FNVHash = FNVHash()
    var digest: [Character] = []
    var halfDigest: Character?
    var halfFnvHash: FNVHash = FNVHash()
    var length: Int = 0

    mutating func reset() {
        fnvHash.reset()
        digest.removeAll()
        halfDigest = nil
        halfFnvHash = FNVHash()
        length = 0
    }
}

/// Streaming SSDeep hash generator
///
/// Use this class for processing large files or streaming data:
/// ```swift
/// let generator = SSDeepGenerator()
/// generator.setTotalLength(fileSize)  // Optional but improves performance
///
/// while let chunk = readNextChunk() {
///     generator.update(chunk)
/// }
///
/// let hash = try generator.finalize()
/// ```
///
/// - Note: This class is NOT thread-safe. Use from a single thread only.
public final class SSDeepGenerator {
    private var rollingHash: RollingHash
    private var blockHashes: [BlockHashState]
    private var totalLength: UInt64 = 0
    private var processedLength: UInt64 = 0
    private var startBlockSize: UInt32
    private var hasSetTotalLength: Bool = false

    /// Create a new SSDeep generator
    public init() {
        self.rollingHash = RollingHash()
        self.blockHashes = (0..<SSDeepConstants.numBlockHashes).map { _ in BlockHashState() }
        self.startBlockSize = SSDeepConstants.minBlockSize
    }

    /// Set the total input length
    ///
    /// Setting the total length allows tracking of the total processed bytes.
    /// Note: Unlike the original optimization, we always process all block sizes
    /// from the minimum to match ssdeep 2.14.1 behavior.
    ///
    /// - Parameter length: The total number of bytes that will be processed
    public func setTotalLength(_ length: UInt64) {
        self.totalLength = length
        self.hasSetTotalLength = true
        // Note: Removed block size pre-calculation to match ssdeep 2.14.1
        // Always process all block sizes starting from minimum (3)
    }

    /// Feed data to the generator
    /// - Parameter data: Data to process
    public func update(_ data: Data) {
        data.withUnsafeBytes { buffer in
            if let bytes = buffer.bindMemory(to: UInt8.self).baseAddress {
                for i in 0..<data.count {
                    processByte(bytes[i])
                }
            }
        }
    }

    /// Feed bytes to the generator
    /// - Parameter bytes: Array of bytes to process
    public func update(_ bytes: [UInt8]) {
        for byte in bytes {
            processByte(byte)
        }
    }

    /// Feed a single byte to the generator
    /// - Parameter byte: The byte to process
    public func update(_ byte: UInt8) {
        processByte(byte)
    }

    /// Finalize and return the hash
    ///
    /// After calling finalize, the generator is reset and can be reused.
    ///
    /// - Parameter options: Options for hash generation
    /// - Returns: The computed SSDeep hash
    /// - Throws: `SSDeepError.inputTooSmall` if input was too small
    public func finalize(options: SSDeepOptions = []) throws -> SSDeepHash {
        defer { reset() }

        // Find the best block size index
        let (blockSizeIndex, blockSize) = findBestBlockSize()

        // Build the hash strings
        var hash1 = buildHashString(at: blockSizeIndex)
        var hash2 = buildHashString(at: blockSizeIndex + 1)

        // Apply sequence elimination if requested
        if options.contains(.eliminateSequences) {
            hash1 = EditDistance.eliminateSequences(hash1)
            hash2 = EditDistance.eliminateSequences(hash2)
        }

        return SSDeepHash(blockSize: blockSize, hash1: hash1, hash2: hash2)
    }

    /// Reset the generator for reuse
    public func reset() {
        rollingHash.reset()
        for i in 0..<blockHashes.count {
            blockHashes[i].reset()
        }
        processedLength = 0
        if !hasSetTotalLength {
            totalLength = 0
            startBlockSize = SSDeepConstants.minBlockSize
        }
    }

    /// Clone the current state
    /// - Returns: A new generator with the same state
    public func clone() -> SSDeepGenerator {
        let newGenerator = SSDeepGenerator()
        newGenerator.rollingHash = self.rollingHash
        newGenerator.blockHashes = self.blockHashes
        newGenerator.totalLength = self.totalLength
        newGenerator.processedLength = self.processedLength
        newGenerator.startBlockSize = self.startBlockSize
        newGenerator.hasSetTotalLength = self.hasSetTotalLength
        return newGenerator
    }

    // MARK: - Private Methods

    private func processByte(_ byte: UInt8) {
        processedLength += 1

        // Update rolling hash
        let h = rollingHash.update(byte)

        // Process each block hash level starting from minimum (index 0)
        // This ensures we track all possible block sizes as ssdeep 2.14.1 does
        for i in 0..<SSDeepConstants.numBlockHashes {
            let blockSize = blockSizeAt(index: i)

            // Update FNV hash for this level
            blockHashes[i].fnvHash.update(byte)

            // Also track the "half" state for the final character
            blockHashes[i].halfFnvHash.update(byte)

            // Check if we've hit a block boundary
            if h % UInt32(blockSize) == UInt32(blockSize - 1) {
                // Emit a character if we haven't filled the digest
                if blockHashes[i].digest.count < SSDeepConstants.spamsumLength {
                    let digestValue = blockHashes[i].fnvHash.digest()
                    blockHashes[i].digest.append(SSDeepBase64.encode(digestValue))
                    blockHashes[i].fnvHash.reset()

                    // Save the half digest if we're at the halfway point
                    if blockHashes[i].digest.count == SSDeepConstants.spamsumLength / 2 {
                        blockHashes[i].halfDigest = blockHashes[i].digest.last
                        blockHashes[i].halfFnvHash.reset()
                    }
                }

                blockHashes[i].length += 1
            }
        }
    }

    private func blockSizeAt(index: Int) -> UInt32 {
        return SSDeepConstants.minBlockSize << UInt32(index)
    }

    private func blockSizeIndexFor(_ blockSize: UInt32) -> Int {
        var index = 0
        var size = SSDeepConstants.minBlockSize
        while size < blockSize && index < SSDeepConstants.numBlockHashes - 1 {
            size *= 2
            index += 1
        }
        return index
    }

    private func findBestBlockSize() -> (index: Int, blockSize: UInt32) {
        // Find the best block size matching ssdeep 2.14.1 behavior
        // We want the smallest block size where:
        // 1. hash1 has reasonable length (>= 32 chars)
        // 2. hash1 is NOT completely filled (< 64 chars)
        // This ensures we don't select a block size that's too small
        for i in 0..<(SSDeepConstants.numBlockHashes - 1) {
            let hash1Length = blockHashes[i].digest.count

            // Select block size with good hash1 length that's not maxed out
            if hash1Length >= SSDeepConstants.spamsumLength / 2 &&
               hash1Length < SSDeepConstants.spamsumLength {
                let bs = blockSizeAt(index: i)
                return (i, bs)
            }
        }

        // If we didn't find a perfect match, use last non-empty hash
        for i in (0..<SSDeepConstants.numBlockHashes - 1).reversed() {
            if blockHashes[i].digest.count > 0 {
                let bs = blockSizeAt(index: i)
                return (i, bs)
            }
        }

        // Fallback to minimum block size
        return (0, SSDeepConstants.minBlockSize)
    }

    private func buildHashString(at index: Int) -> String {
        guard index < SSDeepConstants.numBlockHashes else {
            return ""
        }

        var result = blockHashes[index].digest

        // If the digest is not full, add the final FNV hash value
        if result.count < SSDeepConstants.spamsumLength {
            let finalDigest = blockHashes[index].fnvHash.digest()
            if finalDigest != 0 || result.isEmpty {
                result.append(SSDeepBase64.encode(finalDigest))
            }
        }

        return String(result)
    }
}

// MARK: - Internal Extensions for Cloning

extension RollingHash {
    init(copying other: RollingHash) {
        self = other
    }
}

extension FNVHash {
    init(copying other: FNVHash) {
        self = other
    }
}
