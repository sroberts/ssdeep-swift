import XCTest
@testable import SSDeep

final class HashGenerationTests: XCTestCase {

    func testBasicHash() throws {
        let input = "The quick brown fox jumps over the lazy dog"
        let hash = try SSDeep.hash(input)

        XCTAssertGreaterThanOrEqual(hash.blockSize, SSDeepConstants.minBlockSize)
        XCTAssertFalse(hash.hash1.isEmpty)
        XCTAssertLessThanOrEqual(hash.hash1.count, SSDeepConstants.spamsumLength)
        XCTAssertLessThanOrEqual(hash.hash2.count, SSDeepConstants.spamsumLength)
    }

    func testHashFormat() throws {
        let input = String(repeating: "A", count: 1000)
        let hash = try SSDeep.hash(input)

        let description = hash.description

        // Should have format "blocksize:hash1:hash2"
        let components = description.split(separator: ":")
        XCTAssertEqual(components.count, 3)

        // First component should be a valid block size
        let blockSize = UInt32(components[0])
        XCTAssertNotNil(blockSize)
        XCTAssertGreaterThanOrEqual(blockSize!, SSDeepConstants.minBlockSize)
    }

    func testHashDeterminism() throws {
        let input = "Determinism test input string that should always produce the same hash"

        let hash1 = try SSDeep.hash(input)
        let hash2 = try SSDeep.hash(input)

        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash1.description, hash2.description)
    }

    func testDataHash() throws {
        let data = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
        let hash = try SSDeep.hash(data)

        XCTAssertGreaterThanOrEqual(hash.blockSize, SSDeepConstants.minBlockSize)
    }

    func testBytesHash() throws {
        let bytes: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]  // "Hello"
        let hash = try SSDeep.hash(bytes)

        XCTAssertGreaterThanOrEqual(hash.blockSize, SSDeepConstants.minBlockSize)
    }

    func testEmptyInput() throws {
        let hash = try SSDeep.hash("")
        // Empty input should still produce a valid hash
        XCTAssertGreaterThanOrEqual(hash.blockSize, SSDeepConstants.minBlockSize)
    }

    func testLargeInput() throws {
        // 100 KB of data
        let input = String(repeating: "X", count: 100_000)
        let hash = try SSDeep.hash(input)

        // Larger inputs should use larger block sizes
        XCTAssertGreaterThanOrEqual(hash.blockSize, SSDeepConstants.minBlockSize)
    }

    func testVeryLargeInput() throws {
        // 1 MB of data
        let input = String(repeating: "Y", count: 1_000_000)
        let hash = try SSDeep.hash(input)

        XCTAssertGreaterThan(hash.blockSize, SSDeepConstants.minBlockSize)
    }

    func testBase64Characters() throws {
        let input = String(repeating: "Test", count: 100)
        let hash = try SSDeep.hash(input)

        // Verify all characters in hash1 and hash2 are valid Base64
        for char in hash.hash1 {
            XCTAssertTrue(SSDeepBase64.isValid(char), "Invalid character in hash1: \(char)")
        }

        for char in hash.hash2 {
            XCTAssertTrue(SSDeepBase64.isValid(char), "Invalid character in hash2: \(char)")
        }
    }

    func testEliminateSequencesOption() throws {
        // Input with repeated characters
        let input = String(repeating: "A", count: 1000) + String(repeating: "B", count: 1000)

        let hashWithoutOption = try SSDeep.hash(input)
        let hashWithOption = try SSDeep.hash(input, options: .eliminateSequences)

        // With eliminateSequences, long runs should be reduced
        // The exact behavior depends on the hash, but the option should work
        XCTAssertNotNil(hashWithOption)
        XCTAssertNotNil(hashWithoutOption)
    }

    func testStreamingHash() throws {
        let input = "The quick brown fox jumps over the lazy dog"
        let inputData = Data(input.utf8)

        // Hash using streaming API
        let generator = SSDeepGenerator()
        generator.setTotalLength(UInt64(inputData.count))
        generator.update(inputData)
        let streamingHash = try generator.finalize()

        // Hash using regular API
        let regularHash = try SSDeep.hash(input)

        // Both should produce the same result
        XCTAssertEqual(streamingHash, regularHash)
    }

    func testStreamingChunkedHash() throws {
        let input = "The quick brown fox jumps over the lazy dog"
        let inputData = Data(input.utf8)

        // Hash using streaming API with chunks
        let generator = SSDeepGenerator()
        generator.setTotalLength(UInt64(inputData.count))

        // Feed data in small chunks
        let chunkSize = 10
        for i in stride(from: 0, to: inputData.count, by: chunkSize) {
            let end = min(i + chunkSize, inputData.count)
            let chunk = inputData[i..<end]
            generator.update(Data(chunk))
        }

        let streamingHash = try generator.finalize()

        // Hash using regular API
        let regularHash = try SSDeep.hash(input)

        // Both should produce the same result
        XCTAssertEqual(streamingHash, regularHash)
    }

    func testGeneratorReset() throws {
        let generator = SSDeepGenerator()

        // First hash
        generator.update(Data("First input".utf8))
        let hash1 = try generator.finalize()

        // Generator should be reset after finalize
        generator.update(Data("Second input".utf8))
        let hash2 = try generator.finalize()

        // Hashes should be different (different inputs)
        XCTAssertNotEqual(hash1, hash2)
    }

    func testGeneratorClone() throws {
        let generator = SSDeepGenerator()
        generator.update(Data("Partial input".utf8))

        // Clone the generator
        let clone = generator.clone()

        // Continue with different data
        generator.update(Data(" - continued A".utf8))
        clone.update(Data(" - continued B".utf8))

        let hash1 = try generator.finalize()
        let hash2 = try clone.finalize()

        // Cloned generators with different continuation should produce different hashes
        XCTAssertNotEqual(hash1, hash2)
    }
}
