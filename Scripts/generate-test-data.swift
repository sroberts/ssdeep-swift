#!/usr/bin/env swift

import Foundation

/// Script to generate deterministic test data for fuzzing and edge case testing
/// Run from repository root: swift Scripts/generate-test-data.swift

struct TestDataGenerator {
    let outputDir = "Tests/SSDeepTests/TestData/generated"

    func generateAll() throws {
        print("Generating test data in \(outputDir)...")

        // Create output directory if it doesn't exist
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDir) {
            try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
        }

        // Generate files
        try generateRandomData()
        try generatePathologicalPatterns()
        try generateBoundaryCases()

        print("✅ Test data generation complete!")
    }

    // MARK: - Random Data Generation

    func generateRandomData() throws {
        print("  Generating random data files...")
        let sizes = [
            ("random-1kb.bin", 1024),
            ("random-10kb.bin", 10 * 1024),
            ("random-100kb.bin", 100 * 1024),
            ("random-1mb.bin", 1024 * 1024)
        ]

        for (filename, size) in sizes {
            let data = generateDeterministicRandom(size: size, seed: 12345)
            let path = "\(outputDir)/\(filename)"
            try data.write(to: URL(fileURLWithPath: path))
            print("    ✓ Created \(filename)")
        }
    }

    // MARK: - Pathological Patterns

    func generatePathologicalPatterns() throws {
        print("  Generating pathological pattern files...")

        // Alternating bytes pattern
        var alternating = Data()
        for i in 0..<(10 * 1024) {
            alternating.append(UInt8(i % 2 == 0 ? 0xAA : 0x55))
        }
        try alternating.write(to: URL(fileURLWithPath: "\(outputDir)/pattern-alternating.bin"))
        print("    ✓ Created pattern-alternating.bin")

        // Gradual sequence
        var gradual = Data()
        for i in 0..<(10 * 1024) {
            gradual.append(UInt8(i % 256))
        }
        try gradual.write(to: URL(fileURLWithPath: "\(outputDir)/pattern-gradual.bin"))
        print("    ✓ Created pattern-gradual.bin")

        // Repeated blocks
        let block = Data([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF])
        var repeated = Data()
        for _ in 0..<(10 * 1024 / block.count) {
            repeated.append(block)
        }
        try repeated.write(to: URL(fileURLWithPath: "\(outputDir)/pattern-repeated-blocks.bin"))
        print("    ✓ Created pattern-repeated-blocks.bin")

        // High entropy (random-looking)
        let highEntropy = generateDeterministicRandom(size: 10 * 1024, seed: 99999)
        try highEntropy.write(to: URL(fileURLWithPath: "\(outputDir)/pattern-high-entropy.bin"))
        print("    ✓ Created pattern-high-entropy.bin")

        // Low entropy (mostly zeros with occasional non-zero)
        var lowEntropy = Data(repeating: 0, count: 10 * 1024)
        for i in stride(from: 0, to: 10 * 1024, by: 256) {
            lowEntropy[i] = UInt8.random(in: 1...255)
        }
        try lowEntropy.write(to: URL(fileURLWithPath: "\(outputDir)/pattern-low-entropy.bin"))
        print("    ✓ Created pattern-low-entropy.bin")
    }

    // MARK: - Boundary Cases

    func generateBoundaryCases() throws {
        print("  Generating boundary case files...")

        let sizes = [
            ("boundary-2pow10.bin", 1 << 10),  // 1024 bytes (1 KB)
            ("boundary-2pow12.bin", 1 << 12),  // 4096 bytes (4 KB)
            ("boundary-2pow16.bin", 1 << 16),  // 65536 bytes (64 KB)
            ("boundary-2pow20.bin", 1 << 20),  // 1048576 bytes (1 MB)
        ]

        for (filename, size) in sizes {
            let data = generateDeterministicRandom(size: size, seed: 54321)
            let path = "\(outputDir)/\(filename)"
            try data.write(to: URL(fileURLWithPath: path))
            print("    ✓ Created \(filename)")
        }

        // Edge case: File with only specific byte values
        let allZeros = Data(repeating: 0x00, count: 1024)
        try allZeros.write(to: URL(fileURLWithPath: "\(outputDir)/boundary-all-zeros.bin"))
        print("    ✓ Created boundary-all-zeros.bin")

        let allOnes = Data(repeating: 0xFF, count: 1024)
        try allOnes.write(to: URL(fileURLWithPath: "\(outputDir)/boundary-all-ones.bin"))
        print("    ✓ Created boundary-all-ones.bin")
    }

    // MARK: - Helper Functions

    /// Generate deterministic pseudo-random data using a simple LCG
    /// This ensures the same data is generated across runs for reproducibility
    func generateDeterministicRandom(size: Int, seed: UInt64) -> Data {
        var data = Data()
        data.reserveCapacity(size)

        var state = seed
        for _ in 0..<size {
            // Linear Congruential Generator (LCG)
            // Using parameters from Numerical Recipes
            state = (1103515245 &* state &+ 12345) & 0x7FFFFFFF
            data.append(UInt8(state & 0xFF))
        }

        return data
    }
}

// MARK: - Main Execution

do {
    let generator = TestDataGenerator()
    try generator.generateAll()
} catch {
    print("❌ Error: \(error)")
    exit(1)
}
