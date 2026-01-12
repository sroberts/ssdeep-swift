import XCTest
@testable import SSDeep
import Foundation

/// Reference compatibility tests that validate SSDeep-Swift against the canonical ssdeep 2.14.1 implementation
///
/// These tests ensure byte-for-byte hash compatibility with the original ssdeep tool.
/// Tests are organized into three categories:
/// 1. Golden Hash Tests - Always run, compare against stored reference hashes
/// 2. Live CLI Tests - Run when ssdeep CLI is available, compare against live ssdeep output
/// 3. Cross-Compatibility Tests - Verify interoperability between implementations
final class ReferenceCompatibilityTests: XCTestCase {

    // MARK: - Golden Hash Tests (Always Run)

    func testEssentialVectorsAgainstGoldenHashes() throws {
        let goldenHashes = try loadGoldenHashes()
        var testedCount = 0

        for (filePath, expectedHash) in goldenHashes {
            guard filePath.contains("essential/") else { continue }

            let fileURL = try testDataURL(for: filePath)
            let actualHash = try SSDeep.hashFile(at: fileURL)

            XCTAssertEqual(
                actualHash.description,
                expectedHash,
                """
                Hash mismatch for \(filePath)
                Expected (ssdeep 2.14.1): \(expectedHash)
                Actual (SSDeep-Swift):    \(actualHash)
                """
            )
            testedCount += 1
        }

        XCTAssertGreaterThan(testedCount, 0, "No essential test vectors found")
        print("✅ Tested \(testedCount) essential test vectors")
    }

    func testRealWorldCorpusAgainstGoldenHashes() throws {
        let goldenHashes = try loadGoldenHashes()
        var testedCount = 0

        for (filePath, expectedHash) in goldenHashes {
            guard filePath.contains("real-world/") else { continue }

            let fileURL = try testDataURL(for: filePath)
            let actualHash = try SSDeep.hashFile(at: fileURL)

            XCTAssertEqual(
                actualHash.description,
                expectedHash,
                """
                Hash mismatch for \(filePath)
                Expected (ssdeep 2.14.1): \(expectedHash)
                Actual (SSDeep-Swift):    \(actualHash)
                """
            )
            testedCount += 1
        }

        XCTAssertGreaterThan(testedCount, 0, "No real-world corpus files found")
        print("✅ Tested \(testedCount) real-world corpus files")
    }

    func testGeneratedDataAgainstGoldenHashes() throws {
        let goldenHashes = try loadGoldenHashes()
        var testedCount = 0

        for (filePath, expectedHash) in goldenHashes {
            guard filePath.contains("generated/") else { continue }

            let fileURL = try testDataURL(for: filePath)
            let actualHash = try SSDeep.hashFile(at: fileURL)

            XCTAssertEqual(
                actualHash.description,
                expectedHash,
                """
                Hash mismatch for \(filePath)
                Expected (ssdeep 2.14.1): \(expectedHash)
                Actual (SSDeep-Swift):    \(actualHash)
                """
            )
            testedCount += 1
        }

        XCTAssertGreaterThan(testedCount, 0, "No generated test files found")
        print("✅ Tested \(testedCount) generated test files")
    }

    // MARK: - Live CLI Comparison Tests (Conditional)

    func testLiveComparisonWithSSDeepCLI() throws {
        guard isSSDeepCLIAvailable() else {
            throw XCTSkip("ssdeep CLI not available - skipping live comparison test")
        }

        // Create temporary test file with known content
        let testData = "The quick brown fox jumps over the lazy dog".data(using: .utf8)!
        let testFile = try createTemporaryTestFile(data: testData)
        defer { try? FileManager.default.removeItem(at: testFile) }

        // Hash with our implementation
        let ourHash = try SSDeep.hashFile(at: testFile)

        // Hash with ssdeep CLI
        let cliHash = try runSSDeepCLI(on: testFile)

        XCTAssertEqual(
            ourHash.description,
            cliHash,
            """
            Live comparison failed!
            SSDeep-Swift: \(ourHash)
            ssdeep CLI:   \(cliHash)
            """
        )

        print("✅ Live comparison test passed")
    }

    func testMultipleSizesAgainstCLI() throws {
        guard isSSDeepCLIAvailable() else {
            throw XCTSkip("ssdeep CLI not available")
        }

        let testSizes = [10, 100, 1000, 10_000, 100_000]

        for size in testSizes {
            let data = generateDeterministicData(size: size, seed: 42)
            let tempFile = try createTemporaryTestFile(data: data)
            defer { try? FileManager.default.removeItem(at: tempFile) }

            let ourHash = try SSDeep.hashFile(at: tempFile)
            let cliHash = try runSSDeepCLI(on: tempFile)

            XCTAssertEqual(
                ourHash.description,
                cliHash,
                "Mismatch for \(size) byte file"
            )
        }

        print("✅ Tested \(testSizes.count) different file sizes against CLI")
    }

    // MARK: - Cross-Compatibility Tests

    func testOurHashCanBeComparedBySSDeepCLI() throws {
        guard isSSDeepCLIAvailable() else {
            throw XCTSkip("ssdeep CLI not available")
        }

        // Generate two similar files
        let content1 = "Hello World! This is a test file for SSDeep."
        let content2 = "Hello World! This is a test file for SSDeep!"  // One extra character
        let file1 = try createTemporaryTestFile(content: content1)
        let file2 = try createTemporaryTestFile(content: content2)
        defer {
            try? FileManager.default.removeItem(at: file1)
            try? FileManager.default.removeItem(at: file2)
        }

        // Hash both with our implementation
        let ourHash1 = try SSDeep.hashFile(at: file1)
        let ourHash2 = try SSDeep.hashFile(at: file2)

        // Compare using ssdeep CLI
        let cliSimilarity = try compareUsingSSDeepCLI(hash1: ourHash1.description, hash2: ourHash2.description)

        // Compare using our implementation
        let ourSimilarity = SSDeep.compare(ourHash1, ourHash2)

        XCTAssertEqual(
            ourSimilarity,
            cliSimilarity,
            """
            Similarity score mismatch!
            SSDeep-Swift score: \(ourSimilarity)
            ssdeep CLI score:   \(cliSimilarity)
            Hash1: \(ourHash1)
            Hash2: \(ourHash2)
            """
        )

        print("✅ Cross-compatibility test passed (score: \(ourSimilarity))")
    }

    func testCLIHashCanBeComparedByOurImplementation() throws {
        guard isSSDeepCLIAvailable() else {
            throw XCTSkip("ssdeep CLI not available")
        }

        // Create test file
        let testFile = try createTemporaryTestFile(content: "Test data for comparison")
        defer { try? FileManager.default.removeItem(at: testFile) }

        // Get hash from CLI
        let cliHashString = try runSSDeepCLI(on: testFile)
        let cliHash = try SSDeep.parse(cliHashString)

        // Get hash from our implementation
        let ourHash = try SSDeep.hashFile(at: testFile)

        // They should be identical
        XCTAssertEqual(cliHash, ourHash, "Hashes should be identical")

        // And comparison should work
        let similarity = SSDeep.compare(cliHash, ourHash)
        XCTAssertEqual(similarity, 100, "Identical hashes should have 100% similarity")

        print("✅ CLI hash successfully parsed and compared by our implementation")
    }

    // MARK: - Helper Methods

    private func loadGoldenHashes() throws -> [(String, String)] {
        let goldenHashesURL = try testDataURL(for: "golden-hashes.txt")

        guard FileManager.default.fileExists(atPath: goldenHashesURL.path) else {
            throw XCTSkip("Golden hashes file not found. Run Scripts/generate-golden-hashes.sh first.")
        }

        let content = try String(contentsOf: goldenHashesURL, encoding: .utf8)
        var hashes: [(String, String)] = []

        for line in content.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else { continue }

            let parts = trimmed.split(separator: "|")
            guard parts.count == 2 else { continue }

            hashes.append((String(parts[0]), String(parts[1])))
        }

        return hashes
    }

    private func testDataURL(for relativePath: String) throws -> URL {
        // When running tests, Bundle.module provides access to test resources
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: relativePath, withExtension: nil) {
            return url
        }
        #endif

        // Fallback: construct path relative to source root
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // ReferenceCompatibilityTests.swift
            .deletingLastPathComponent()  // SSDeepTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // repository root

        return sourceRoot
            .appendingPathComponent(relativePath)
    }

    private func isSSDeepCLIAvailable() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["which", "ssdeep"]
        task.standardOutput = Pipe()
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func runSSDeepCLI(on fileURL: URL) throws -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["ssdeep", "-b", fileURL.path]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        try task.run()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else {
            throw TestError.ssdeepCLIFailed(exitCode: task.terminationStatus)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // ssdeep -b outputs just the hash on the last line
        let hash = output.split(separator: "\n").last?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !hash.isEmpty else {
            throw TestError.ssdeepCLIEmptyOutput
        }

        // Remove CSV format (hash is first field)
        return String(hash.split(separator: ",").first ?? "")
    }

    private func compareUsingSSDeepCLI(hash1: String, hash2: String) throws -> Int {
        // Create temp files with the hash strings
        let tempDir = FileManager.default.temporaryDirectory
        let hash1File = tempDir.appendingPathComponent("hash1.txt")
        let hash2File = tempDir.appendingPathComponent("hash2.txt")

        try hash1.write(to: hash1File, atomically: true, encoding: .utf8)
        try hash2.write(to: hash2File, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: hash1File)
            try? FileManager.default.removeItem(at: hash2File)
        }

        // Use ssdeep -a to compare signature strings
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["ssdeep", "-a", hash1, hash2]

        let pipe = Pipe()
        task.standardOutput = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // Parse similarity score from output
        // Output format is typically: "hash1 matches hash2 (score)"
        if let match = output.range(of: "\\((\\d+)\\)", options: .regularExpression) {
            let scoreStr = output[match].dropFirst().dropLast()
            return Int(scoreStr) ?? 0
        }

        return 0
    }

    private func createTemporaryTestFile(content: String) throws -> URL {
        try createTemporaryTestFile(data: content.data(using: .utf8)!)
    }

    private func createTemporaryTestFile(data: Data) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString + ".bin")
        try data.write(to: tempFile)
        return tempFile
    }

    private func generateDeterministicData(size: Int, seed: UInt64) -> Data {
        var data = Data()
        data.reserveCapacity(size)

        var state = seed
        for _ in 0..<size {
            state = (1103515245 &* state &+ 12345) & 0x7FFFFFFF
            data.append(UInt8(state & 0xFF))
        }

        return data
    }

    // MARK: - Error Types

    enum TestError: Error, CustomStringConvertible {
        case ssdeepCLIFailed(exitCode: Int32)
        case ssdeepCLIEmptyOutput
        case invalidTestData

        var description: String {
            switch self {
            case .ssdeepCLIFailed(let code):
                return "ssdeep CLI failed with exit code \(code)"
            case .ssdeepCLIEmptyOutput:
                return "ssdeep CLI produced no output"
            case .invalidTestData:
                return "Invalid test data"
            }
        }
    }
}
