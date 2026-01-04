# SSDeep

[![CI](https://github.com/sroberts/ssdeep-swift/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/ssdeep-swift/actions/workflows/ci.yml)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20visionOS%20|%20Linux-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A pure Swift implementation of the SSDeep fuzzy hashing library, providing context-triggered piecewise hashing (CTPH) functionality compatible with [ssdeep 2.14.1](https://github.com/ssdeep-project/ssdeep).

## Features

- **Pure Swift** - Zero external C dependencies
- **Cross-Platform** - Works on macOS, iOS, tvOS, watchOS, visionOS, and Linux
- **Modern Swift** - Supports Swift 5.9+ with strict concurrency
- **Streaming API** - Efficiently hash large files with chunked processing
- **Async/Await** - Native async support for file hashing
- **Full Compatibility** - Hash output compatible with ssdeep 2.14.1

## What is SSDeep?

SSDeep implements context-triggered piecewise hashing (CTPH), also known as fuzzy hashing. Unlike cryptographic hashes (SHA-256, MD5) that produce completely different outputs for even minor input changes, CTPH produces similar hashes for similar inputs, enabling similarity detection between files.

### Use Cases

- Malware detection and classification
- Digital forensics (finding similar files)
- Detecting document modifications
- Content deduplication
- Plagiarism detection
- File clustering

## Installation

### Swift Package Manager

Add SSDeep to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/ssdeep-swift.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SSDeep"]
)
```

## Usage

### Basic Hashing

```swift
import SSDeep

// Hash a string
let hash = try SSDeep.hash("Hello, World!")
print(hash)  // e.g., "3:abc:def"

// Hash data
let data = Data([0x01, 0x02, 0x03, 0x04])
let dataHash = try SSDeep.hash(data)

// Hash bytes
let bytes: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]
let bytesHash = try SSDeep.hash(bytes)

// Hash a file
let fileHash = try SSDeep.hashFile(at: "/path/to/file.txt")
let urlHash = try SSDeep.hashFile(at: URL(fileURLWithPath: "/path/to/file.txt"))
```

### Comparing Hashes

```swift
import SSDeep

let hash1 = try SSDeep.hashFile(at: "file1.txt")
let hash2 = try SSDeep.hashFile(at: "file2.txt")

// Compare returns a similarity score from 0-100
let similarity = SSDeep.compare(hash1, hash2)
print("Similarity: \(similarity)%")

if similarity > 50 {
    print("Files are similar!")
}

// Compare hash strings directly
let score = try SSDeep.compare("96:abc123:def456", "96:abc124:def457")
```

### Streaming Large Files

For memory-efficient processing of large files:

```swift
import SSDeep

let generator = SSDeepGenerator()

// Optionally set total length for optimal block size calculation
generator.setTotalLength(fileSize)

// Feed data in chunks
while let chunk = readNextChunk() {
    generator.update(chunk)
}

let hash = try generator.finalize()
```

### Async File Hashing

```swift
import SSDeep

// Async file hashing
let hash = try await SSDeep.hashFile(at: fileURL)

// Process multiple files concurrently
let hashes = try await withThrowingTaskGroup(of: SSDeepHash.self) { group in
    for url in fileURLs {
        group.addTask {
            try await SSDeep.hashFile(at: url)
        }
    }
    return try await group.reduce(into: []) { $0.append($1) }
}
```

### Hash Parsing and Validation

```swift
import SSDeep

// Parse a hash string
let hash = try SSDeep.parse("96:abc123:def456")
print(hash.blockSize)  // 96
print(hash.hash1)      // "abc123"
print(hash.hash2)      // "def456"

// Validate format
if SSDeep.isValid("96:abc:def") {
    print("Valid hash!")
}

// SSDeepHash is LosslessStringConvertible
if let hash = SSDeepHash("96:abc:def") {
    print(hash)
}
```

### Options

```swift
import SSDeep

// Eliminate sequences of more than 3 consecutive repeated characters
let hash = try SSDeep.hash(data, options: .eliminateSequences)
```

## Hash Format

SSDeep hashes follow this format:

```
blocksize:hash1:hash2
```

- **blocksize**: Integer representing the block size used (minimum 3)
- **hash1**: Base64-encoded signature for the primary block size (max 64 characters)
- **hash2**: Base64-encoded signature for double the block size (max 64 characters)

Example:
```
96:s4Ud1Lj96tHHlZDrwciQmA+4uy1I0G4HYuL8N3TzS8QsO/wqWXLcMSx:sF1LjEtHHlZDrJzrhuyZvHYm8tKp/RWO
```

## API Reference

### SSDeep

Main static API for hashing and comparison.

```swift
// Hash generation
static func hash(_ data: Data, options: SSDeepOptions = []) throws -> SSDeepHash
static func hash(_ bytes: [UInt8], options: SSDeepOptions = []) throws -> SSDeepHash
static func hash(_ string: String, options: SSDeepOptions = []) throws -> SSDeepHash
static func hashFile(at path: String, options: SSDeepOptions = []) throws -> SSDeepHash
static func hashFile(at url: URL, options: SSDeepOptions = []) throws -> SSDeepHash

// Comparison (returns 0-100)
static func compare(_ hash1: SSDeepHash, _ hash2: SSDeepHash) -> Int
static func compare(_ hash1: String, _ hash2: String) throws -> Int

// Parsing
static func parse(_ hashString: String) throws -> SSDeepHash
static func isValid(_ hashString: String) -> Bool
```

### SSDeepHash

Represents a parsed SSDeep hash. Conforms to `Hashable`, `Codable`, `Sendable`, and `LosslessStringConvertible`.

```swift
struct SSDeepHash {
    let blockSize: UInt32
    let hash1: String
    let hash2: String
}
```

### SSDeepGenerator

Streaming API for processing data incrementally.

```swift
class SSDeepGenerator {
    init()
    func setTotalLength(_ length: UInt64)
    func update(_ data: Data)
    func update(_ bytes: [UInt8])
    func update(_ byte: UInt8)
    func finalize(options: SSDeepOptions = []) throws -> SSDeepHash
    func reset()
    func clone() -> SSDeepGenerator
}
```

### SSDeepOptions

Options for hash generation.

```swift
struct SSDeepOptions: OptionSet {
    static let eliminateSequences  // Reduce runs of repeated characters
    static let noTruncate          // Do not truncate the hash
}
```

### SSDeepError

Error types for SSDeep operations.

```swift
enum SSDeepError: Error {
    case inputTooSmall
    case inputTooLarge
    case invalidHash
    case invalidBlockSize
    case incompatibleBlockSizes
    case fileNotFound
    case fileReadError(String)
}
```

## Platform Support

| Platform | Minimum Version |
|----------|-----------------|
| macOS | 10.15 (Catalina) |
| iOS | 13.0 |
| tvOS | 13.0 |
| watchOS | 6.0 |
| visionOS | 1.0 |
| Linux | Swift 5.9+ |

## Security Considerations

SSDeep is **NOT** a cryptographic hash function and should **NOT** be used for:
- Password hashing
- Digital signatures
- Message authentication codes
- Any security-critical application requiring collision resistance

SSDeep is appropriate for:
- Similarity detection (its primary purpose)
- Clustering and classification
- Fuzzy matching
- Content identification (non-security contexts)

## Algorithm

SSDeep implements the algorithm described in:

> Kornblum, J. (2006). "Identifying almost identical files using context triggered piecewise hashing." Digital Investigation, 3(S), 91-97.

The algorithm uses:
- A rolling hash with a 7-byte sliding window
- FNV-1 hash for block signatures
- Weighted edit distance for comparison (insertion=1, deletion=1, substitution=3, transposition=5)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [SSDeep Project](https://github.com/ssdeep-project/ssdeep)
- [SSDeep Documentation](https://ssdeep-project.github.io/ssdeep/)
- Kornblum, J. (2006). "Identifying almost identical files using context triggered piecewise hashing."
