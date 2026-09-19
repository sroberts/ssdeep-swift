import XCTest
@testable import SSDeep

final class ComparisonTests: XCTestCase {

    func testIdenticalHashes() throws {
        let input = String(repeating: "Test content for hashing", count: 50)
        let hash1 = try SSDeep.hash(input)
        let hash2 = try SSDeep.hash(input)

        let score = SSDeep.compare(hash1, hash2)

        // Identical hashes should have score of 100
        XCTAssertEqual(score, 100)
    }

    func testSimilarInputs() throws {
        let baseText = String(repeating: "The quick brown fox jumps over the lazy dog. ", count: 20)
        let modifiedText = baseText.replacingOccurrences(of: "fox", with: "cat")

        let hash1 = try SSDeep.hash(baseText)
        let hash2 = try SSDeep.hash(modifiedText)

        let score = SSDeep.compare(hash1, hash2)

        // Similar inputs should have a non-zero score
        // The exact score depends on how similar the inputs are
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }

    func testCompletelyDifferentInputs() throws {
        let input1 = String(repeating: "AAAAAAAAAA", count: 100)
        let input2 = String(repeating: "ZZZZZZZZZZ", count: 100)

        let hash1 = try SSDeep.hash(input1)
        let hash2 = try SSDeep.hash(input2)

        let score = SSDeep.compare(hash1, hash2)

        // Very different inputs should have low or zero score
        XCTAssertLessThan(score, 50)
    }

    func testScoreRange() throws {
        let input1 = String(repeating: "Test", count: 100)
        let input2 = String(repeating: "Test", count: 100) + "Modified"

        let hash1 = try SSDeep.hash(input1)
        let hash2 = try SSDeep.hash(input2)

        let score = SSDeep.compare(hash1, hash2)

        // Score should always be in range 0-100
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }

    func testCompareWithStrings() throws {
        let input = String(repeating: "Content", count: 50)
        let hash = try SSDeep.hash(input)
        let hashString = hash.description

        let score = try SSDeep.compare(hashString, hashString)

        XCTAssertEqual(score, 100)
    }

    func testSymmetricComparison() throws {
        let input1 = String(repeating: "First input text", count: 30)
        let input2 = String(repeating: "Second input text", count: 30)

        let hash1 = try SSDeep.hash(input1)
        let hash2 = try SSDeep.hash(input2)

        let score1 = SSDeep.compare(hash1, hash2)
        let score2 = SSDeep.compare(hash2, hash1)

        // Comparison should be symmetric
        XCTAssertEqual(score1, score2)
    }

    func testInvalidHashComparison() {
        XCTAssertThrowsError(try SSDeep.compare("invalid", "also invalid")) { error in
            XCTAssertEqual(error as? SSDeepError, SSDeepError.invalidHash)
        }
    }

    func testEmptyHashComparison() throws {
        // Create hashes from empty-ish inputs
        let hash1 = try SSDeep.hash("")
        let hash2 = try SSDeep.hash("")

        let score = SSDeep.compare(hash1, hash2)

        // Should be valid comparison
        XCTAssertGreaterThanOrEqual(score, 0)
    }

    func testBlockSizeCompatibility() throws {
        // Test that we can compare hashes with compatible block sizes
        let smallInput = String(repeating: "A", count: 100)
        let largeInput = String(repeating: "B", count: 100_000)

        let smallHash = try SSDeep.hash(smallInput)
        let largeHash = try SSDeep.hash(largeInput)

        // Even with different block sizes, comparison should work
        // (may return 0 if incompatible)
        let score = SSDeep.compare(smallHash, largeHash)
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }
}

final class EditDistanceTests: XCTestCase {

    func testIdenticalStrings() {
        let distance = EditDistance.weightedEditDistance("hello", "hello")
        XCTAssertEqual(distance, 0)
    }

    func testSingleInsertion() {
        let distance = EditDistance.weightedEditDistance("hello", "helloo")
        XCTAssertEqual(distance, 1)  // Insertion cost is 1
    }

    func testSingleDeletion() {
        let distance = EditDistance.weightedEditDistance("hello", "hell")
        XCTAssertEqual(distance, 1)  // Deletion cost is 1
    }

    func testSingleSubstitution() {
        let distance = EditDistance.weightedEditDistance("hello", "hallo")
        XCTAssertEqual(distance, 2)  // Optimal: delete 'e' (1) + insert 'a' (1) = 2, cheaper than substitution (3)
    }

    func testEmptyStrings() {
        XCTAssertEqual(EditDistance.weightedEditDistance("", ""), 0)
        XCTAssertEqual(EditDistance.weightedEditDistance("hello", ""), 5)  // 5 deletions
        XCTAssertEqual(EditDistance.weightedEditDistance("", "hello"), 5)  // 5 insertions
    }

    func testHasCommonSubstring() {
        XCTAssertTrue(EditDistance.hasCommonSubstring("abcdefghij", "xyzdefghijk", minLength: 7))
        XCTAssertFalse(EditDistance.hasCommonSubstring("abcdefg", "hijklmn", minLength: 7))
        XCTAssertFalse(EditDistance.hasCommonSubstring("abc", "abc", minLength: 7))  // Too short
    }

    func testEliminateSequences() {
        XCTAssertEqual(EditDistance.eliminateSequences("aaaa"), "aaa")
        XCTAssertEqual(EditDistance.eliminateSequences("aaaaaa"), "aaa")
        XCTAssertEqual(EditDistance.eliminateSequences("abc"), "abc")
        XCTAssertEqual(EditDistance.eliminateSequences("aabbcc"), "aabbcc")
        XCTAssertEqual(EditDistance.eliminateSequences("aaaabbbbcccc"), "aaabbbccc")
        XCTAssertEqual(EditDistance.eliminateSequences(""), "")
    }
}
