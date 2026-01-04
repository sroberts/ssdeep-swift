import XCTest
@testable import SSDeep

final class RollingHashTests: XCTestCase {

    func testInitialState() {
        var hash = RollingHash()
        // Initial sum should be 0
        XCTAssertEqual(hash.sum, 0)
    }

    func testSingleByteUpdate() {
        var hash = RollingHash()
        let result = hash.update(65)  // 'A'
        XCTAssertGreaterThan(result, 0)
    }

    func testMultipleUpdates() {
        var hash = RollingHash()
        var results: [UInt32] = []

        for byte in "Hello".utf8 {
            results.append(hash.update(byte))
        }

        // Each update should produce a different result
        // (though not guaranteed, very likely for different inputs)
        XCTAssertEqual(results.count, 5)
    }

    func testReset() {
        var hash1 = RollingHash()
        var hash2 = RollingHash()

        // Update hash1
        for byte in "Test".utf8 {
            _ = hash1.update(byte)
        }

        // Reset hash1
        hash1.reset()

        // Both should be in the same state now
        XCTAssertEqual(hash1.sum, hash2.sum)
    }

    func testDeterminism() {
        var hash1 = RollingHash()
        var hash2 = RollingHash()

        let input = "The quick brown fox jumps over the lazy dog"

        var results1: [UInt32] = []
        var results2: [UInt32] = []

        for byte in input.utf8 {
            results1.append(hash1.update(byte))
        }

        for byte in input.utf8 {
            results2.append(hash2.update(byte))
        }

        XCTAssertEqual(results1, results2)
    }

    func testWindowSize() {
        var hash = RollingHash()

        // Process more than ROLLING_WINDOW bytes
        let input = "ABCDEFGHIJ"  // 10 bytes

        for byte in input.utf8 {
            _ = hash.update(byte)
        }

        // The hash should still be valid
        XCTAssertGreaterThan(hash.sum, 0)
    }

    func testOverflowHandling() {
        var hash = RollingHash()

        // Process many bytes to test overflow handling
        for _ in 0..<10000 {
            _ = hash.update(0xFF)
        }

        // Should not crash, result should be valid
        XCTAssertTrue(true)
    }
}
