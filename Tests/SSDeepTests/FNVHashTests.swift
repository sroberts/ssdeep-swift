import XCTest
@testable import SSDeep

final class FNVHashTests: XCTestCase {

    func testInitialState() {
        let hash = FNVHash()
        // Initial full hash should be HASH_INIT (0x27 = 39)
        XCTAssertEqual(hash.fullHash, 0x27)
    }

    func testSingleByteUpdate() {
        var hash = FNVHash()
        hash.update(65)  // 'A'

        // Digest should be in range 0-63
        XCTAssertLessThan(hash.digest(), 64)
    }

    func testDigestRange() {
        var hash = FNVHash()

        // Test with various inputs
        for byte: UInt8 in 0..<255 {
            hash.update(byte)
            let digest = hash.digest()
            XCTAssertLessThan(digest, 64, "Digest should always be < 64")
        }
    }

    func testReset() {
        var hash = FNVHash()

        // Update with some data
        for byte in "Hello".utf8 {
            hash.update(byte)
        }

        // Reset
        hash.reset()

        // Should be back to initial state
        XCTAssertEqual(hash.fullHash, 0x27)
    }

    func testDeterminism() {
        var hash1 = FNVHash()
        var hash2 = FNVHash()

        let input = "Test input string"

        for byte in input.utf8 {
            hash1.update(byte)
        }

        for byte in input.utf8 {
            hash2.update(byte)
        }

        XCTAssertEqual(hash1.fullHash, hash2.fullHash)
        XCTAssertEqual(hash1.digest(), hash2.digest())
    }

    func testDifferentInputs() {
        var hash1 = FNVHash()
        var hash2 = FNVHash()

        for byte in "Hello".utf8 {
            hash1.update(byte)
        }

        for byte in "World".utf8 {
            hash2.update(byte)
        }

        // Different inputs should (very likely) produce different hashes
        XCTAssertNotEqual(hash1.fullHash, hash2.fullHash)
    }

    func testFNVPrime() {
        // Verify the FNV prime is correct
        XCTAssertEqual(SSDeepConstants.fnvPrime, 0x01000193)
    }

    func testHashInit() {
        // Verify the hash init value is correct
        XCTAssertEqual(SSDeepConstants.hashInit, 0x27)
        XCTAssertEqual(SSDeepConstants.hashInit, 39)
    }
}
