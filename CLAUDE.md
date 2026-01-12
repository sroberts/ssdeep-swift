# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SSDeep-Swift is a pure Swift implementation of the SSDeep fuzzy hashing library, implementing context-triggered piecewise hashing (CTPH). The library is designed to be cross-platform, supporting macOS, iOS, tvOS, watchOS, visionOS, and Linux with zero external C dependencies. It's compatible with ssdeep 2.14.1 hash outputs.

## Build & Test Commands

### Basic Commands
```bash
# Build the project
swift build

# Build with verbose output
swift build -v

# Run all tests
swift test

# Run tests with verbose output
swift test -v

# Run tests with code coverage
swift test --enable-code-coverage
```

### Platform-Specific Testing
```bash
# Test on iOS Simulator
xcodebuild test \
  -scheme SSDeep \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Test on tvOS Simulator
xcodebuild test \
  -scheme SSDeep \
  -destination 'platform=tvOS Simulator,name=Apple TV,OS=latest'

# Build for watchOS (testing not supported on watchOS)
xcodebuild build \
  -scheme SSDeep \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm),OS=latest'
```

### Running Individual Tests
```bash
# Run specific test case
swift test --filter SSDeepTests.HashGenerationTests

# Run specific test method
swift test --filter SSDeepTests.HashGenerationTests/testBasicHash
```

## Architecture Overview

### Core Components

1. **SSDeep (enum)** - Main static API entry point
   - Provides static methods for hashing data, strings, and files
   - Implements hash comparison using weighted edit distance
   - Supports both synchronous and async APIs (async available on Swift 5.5+)

2. **SSDeepGenerator (class)** - Streaming hash generator
   - **NOT thread-safe** - use from single thread only
   - Maintains state for incremental data processing
   - Uses rolling hash + FNV hash + block-based signatures
   - Processes multiple block sizes simultaneously (controlled by `SSDeepConstants.numBlockHashes`)

3. **SSDeepHash (struct)** - Hash representation
   - Format: `blocksize:hash1:hash2`
   - Conforms to `Hashable`, `Codable`, `Sendable`, `LosslessStringConvertible`
   - Encodes as a simple string in JSON (not as object)

### Internal Implementation

The algorithm uses three hashing primitives located in `Sources/SSDeep/Internal/`:

- **RollingHash** - 7-byte sliding window for detecting block boundaries
  - Uses wrapping arithmetic (`&+`, `&-`) for performance
  - Determines when to emit hash characters based on trigger condition

- **FNVHash** - Fowler-Noll-Vo hash for block signatures
  - Generates the actual hash values for each block

- **EditDistance** - Weighted edit distance for comparison
  - Costs: insertion=1, deletion=1, substitution=3, transposition=5
  - Implements common substring check as optimization

### Key Design Patterns

1. **Multi-Level Block Processing**
   - Generator maintains state for multiple block sizes simultaneously
   - Each level has its own `BlockHashState` with independent FNV hash and digest
   - Optimal block size is determined at finalization based on which level produces best results

2. **Streaming API Pattern**
   - `SSDeepGenerator` maintains mutable state across `update()` calls
   - Call `setTotalLength()` before processing for optimal block size calculation
   - `finalize()` automatically resets the generator for reuse
   - `clone()` available for branching computation

3. **Options Pattern**
   - `SSDeepOptions` is an `OptionSet` for extensibility
   - Currently supports `.eliminateSequences` and `.noTruncate`
   - Applied during finalization, not during update phase

## Important Constraints

- **Minimum input size**: 3 bytes (throws `SSDeepError.inputTooSmall`)
- **Block size minimum**: `SSDeepConstants.minBlockSize` (3)
- **Hash component max length**: `SSDeepConstants.spamsumLength` (64 characters)
- **Rolling window size**: 7 bytes (`SSDeepConstants.rollingWindow`)
- **Strict concurrency**: Enabled in Package.swift
- **Platform versions**: macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+, visionOS 1+

## Testing Structure

Test files in `Tests/SSDeepTests/`:
- `HashGenerationTests.swift` - Core hashing functionality
- `ComparisonTests.swift` - Hash comparison logic
- `HashParsingTests.swift` - String parsing and validation
- `FNVHashTests.swift` - FNV hash implementation
- `RollingHashTests.swift` - Rolling hash implementation

## CI/CD

The project uses GitHub Actions (`.github/workflows/ci.yml`) with jobs for:
- macOS testing (Swift 5.9 & 5.10)
- Linux testing (Swift 5.9 & 5.10)
- iOS Simulator testing
- tvOS Simulator testing
- watchOS build (no tests)
- Code coverage reporting

## Security Note

SSDeep is NOT cryptographically secure and should NOT be used for password hashing, signatures, or security-critical applications. It is designed for similarity detection only.
