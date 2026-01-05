import XCTest
@testable import SSDeepTests

fileprivate extension ComparisonTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__ComparisonTests = [
        ("testBlockSizeCompatibility", testBlockSizeCompatibility),
        ("testCompareWithStrings", testCompareWithStrings),
        ("testCompletelyDifferentInputs", testCompletelyDifferentInputs),
        ("testEmptyHashComparison", testEmptyHashComparison),
        ("testIdenticalHashes", testIdenticalHashes),
        ("testInvalidHashComparison", testInvalidHashComparison),
        ("testScoreRange", testScoreRange),
        ("testSimilarInputs", testSimilarInputs),
        ("testSymmetricComparison", testSymmetricComparison)
    ]
}

fileprivate extension EditDistanceTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__EditDistanceTests = [
        ("testEliminateSequences", testEliminateSequences),
        ("testEmptyStrings", testEmptyStrings),
        ("testHasCommonSubstring", testHasCommonSubstring),
        ("testIdenticalStrings", testIdenticalStrings),
        ("testSingleDeletion", testSingleDeletion),
        ("testSingleInsertion", testSingleInsertion),
        ("testSingleSubstitution", testSingleSubstitution)
    ]
}

fileprivate extension FNVHashTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__FNVHashTests = [
        ("testDeterminism", testDeterminism),
        ("testDifferentInputs", testDifferentInputs),
        ("testDigestRange", testDigestRange),
        ("testFNVPrime", testFNVPrime),
        ("testHashInit", testHashInit),
        ("testInitialState", testInitialState),
        ("testReset", testReset),
        ("testSingleByteUpdate", testSingleByteUpdate)
    ]
}

fileprivate extension HashGenerationTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__HashGenerationTests = [
        ("testBase64Characters", testBase64Characters),
        ("testBasicHash", testBasicHash),
        ("testBytesHash", testBytesHash),
        ("testDataHash", testDataHash),
        ("testEliminateSequencesOption", testEliminateSequencesOption),
        ("testEmptyInput", testEmptyInput),
        ("testGeneratorClone", testGeneratorClone),
        ("testGeneratorReset", testGeneratorReset),
        ("testHashDeterminism", testHashDeterminism),
        ("testHashFormat", testHashFormat),
        ("testLargeInput", testLargeInput),
        ("testStreamingChunkedHash", testStreamingChunkedHash),
        ("testStreamingHash", testStreamingHash),
        ("testVeryLargeInput", testVeryLargeInput)
    ]
}

fileprivate extension HashParsingTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__HashParsingTests = [
        ("testAllBase64Characters", testAllBase64Characters),
        ("testCodableAsString", testCodableAsString),
        ("testEmptyHashComponents", testEmptyHashComponents),
        ("testHashDescription", testHashDescription),
        ("testHashEquatable", testHashEquatable),
        ("testHashHashable", testHashHashable),
        ("testInvalidBase64Characters", testInvalidBase64Characters),
        ("testInvalidBlockSize", testInvalidBlockSize),
        ("testInvalidFormat", testInvalidFormat),
        ("testIsValid", testIsValid),
        ("testLosslessStringConvertible", testLosslessStringConvertible),
        ("testValidHashParsing", testValidHashParsing)
    ]
}

fileprivate extension RollingHashTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__RollingHashTests = [
        ("testDeterminism", testDeterminism),
        ("testInitialState", testInitialState),
        ("testMultipleUpdates", testMultipleUpdates),
        ("testOverflowHandling", testOverflowHandling),
        ("testReset", testReset),
        ("testSingleByteUpdate", testSingleByteUpdate),
        ("testWindowSize", testWindowSize)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __SSDeepTests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ComparisonTests.__allTests__ComparisonTests),
        testCase(EditDistanceTests.__allTests__EditDistanceTests),
        testCase(FNVHashTests.__allTests__FNVHashTests),
        testCase(HashGenerationTests.__allTests__HashGenerationTests),
        testCase(HashParsingTests.__allTests__HashParsingTests),
        testCase(RollingHashTests.__allTests__RollingHashTests)
    ]
}