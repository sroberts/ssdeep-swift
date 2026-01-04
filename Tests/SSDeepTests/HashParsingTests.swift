import XCTest
@testable import SSDeep

final class HashParsingTests: XCTestCase {

    func testValidHashParsing() throws {
        let hashString = "96:abc123:def456"
        let hash = try SSDeep.parse(hashString)

        XCTAssertEqual(hash.blockSize, 96)
        XCTAssertEqual(hash.hash1, "abc123")
        XCTAssertEqual(hash.hash2, "def456")
    }

    func testHashDescription() throws {
        let hashString = "48:ABC:XYZ"
        let hash = try SSDeep.parse(hashString)

        XCTAssertEqual(hash.description, hashString)
    }

    func testInvalidFormat() {
        // Missing component
        XCTAssertThrowsError(try SSDeep.parse("96:abc")) { error in
            XCTAssertEqual(error as? SSDeepError, SSDeepError.invalidHash)
        }

        // Too many components
        XCTAssertThrowsError(try SSDeep.parse("96:abc:def:ghi")) { error in
            XCTAssertEqual(error as? SSDeepError, SSDeepError.invalidHash)
        }

        // Non-numeric block size
        XCTAssertThrowsError(try SSDeep.parse("abc:def:ghi")) { error in
            XCTAssertEqual(error as? SSDeepError, SSDeepError.invalidHash)
        }
    }

    func testInvalidBlockSize() {
        // Block size too small
        XCTAssertThrowsError(try SSDeep.parse("1:abc:def")) { error in
            XCTAssertEqual(error as? SSDeepError, SSDeepError.invalidBlockSize)
        }

        // Block size of 0
        XCTAssertThrowsError(try SSDeep.parse("0:abc:def")) { error in
            XCTAssertEqual(error as? SSDeepError, SSDeepError.invalidBlockSize)
        }
    }

    func testInvalidBase64Characters() {
        // Invalid character in hash1
        XCTAssertThrowsError(try SSDeep.parse("96:abc!:def")) { error in
            XCTAssertEqual(error as? SSDeepError, SSDeepError.invalidHash)
        }

        // Invalid character in hash2
        XCTAssertThrowsError(try SSDeep.parse("96:abc:def@")) { error in
            XCTAssertEqual(error as? SSDeepError, SSDeepError.invalidHash)
        }
    }

    func testEmptyHashComponents() throws {
        // Empty hash1 is valid
        let hash1 = try SSDeep.parse("96::def")
        XCTAssertEqual(hash1.hash1, "")
        XCTAssertEqual(hash1.hash2, "def")

        // Empty hash2 is valid
        let hash2 = try SSDeep.parse("96:abc:")
        XCTAssertEqual(hash2.hash1, "abc")
        XCTAssertEqual(hash2.hash2, "")

        // Both empty is valid
        let hash3 = try SSDeep.parse("96::")
        XCTAssertEqual(hash3.hash1, "")
        XCTAssertEqual(hash3.hash2, "")
    }

    func testIsValid() {
        XCTAssertTrue(SSDeep.isValid("96:abc:def"))
        XCTAssertTrue(SSDeep.isValid("3:A:B"))
        XCTAssertTrue(SSDeep.isValid("192::"))

        XCTAssertFalse(SSDeep.isValid("invalid"))
        XCTAssertFalse(SSDeep.isValid("96:abc"))
        XCTAssertFalse(SSDeep.isValid("0:abc:def"))
    }

    func testHashEquatable() throws {
        let hash1 = try SSDeep.parse("96:abc:def")
        let hash2 = try SSDeep.parse("96:abc:def")
        let hash3 = try SSDeep.parse("96:abc:xyz")

        XCTAssertEqual(hash1, hash2)
        XCTAssertNotEqual(hash1, hash3)
    }

    func testHashHashable() throws {
        let hash1 = try SSDeep.parse("96:abc:def")
        let hash2 = try SSDeep.parse("96:abc:def")

        var set: Set<SSDeepHash> = []
        set.insert(hash1)
        set.insert(hash2)

        XCTAssertEqual(set.count, 1)
    }

    func testLosslessStringConvertible() {
        let hash = SSDeepHash("96:abc:def")
        XCTAssertNotNil(hash)
        XCTAssertEqual(hash?.blockSize, 96)
        XCTAssertEqual(hash?.hash1, "abc")
        XCTAssertEqual(hash?.hash2, "def")

        let invalidHash = SSDeepHash("invalid")
        XCTAssertNil(invalidHash)
    }

    func testCodableAsString() throws {
        let originalHash = try SSDeep.parse("96:abc:def")

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalHash)
        let jsonString = String(data: data, encoding: .utf8)

        // Should encode as a simple string
        XCTAssertEqual(jsonString, "\"96:abc:def\"")

        // Decode
        let decoder = JSONDecoder()
        let decodedHash = try decoder.decode(SSDeepHash.self, from: data)

        XCTAssertEqual(originalHash, decodedHash)
    }

    func testAllBase64Characters() throws {
        // All valid Base64 characters
        let allChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

        // Split into two parts for hash1 and hash2
        let half = allChars.count / 2
        let hash1Chars = String(allChars.prefix(half))
        let hash2Chars = String(allChars.suffix(half))

        let hashString = "96:\(hash1Chars):\(hash2Chars)"
        let hash = try SSDeep.parse(hashString)

        XCTAssertEqual(hash.hash1, hash1Chars)
        XCTAssertEqual(hash.hash2, hash2Chars)
    }
}
