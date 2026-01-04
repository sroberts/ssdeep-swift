/// Rolling hash implementation for SSDeep
///
/// The rolling hash operates on a 7-byte sliding window and produces
/// a pseudo-random value based solely on the current context.
struct RollingHash {
    private var h1: UInt32 = 0
    private var h2: UInt32 = 0
    private var h3: UInt32 = 0
    private var n: UInt32 = 0
    private var window: [UInt8]

    init() {
        self.window = Array(repeating: 0, count: SSDeepConstants.rollingWindow)
    }

    /// Update the rolling hash with a new byte and return the current hash value
    /// - Parameter byte: The next byte to process
    /// - Returns: The current rolling hash value
    @inline(__always)
    mutating func update(_ byte: UInt8) -> UInt32 {
        let index = Int(n % UInt32(SSDeepConstants.rollingWindow))
        let oldByte = window[index]

        h2 = h2 &- h1
        h2 = h2 &+ UInt32(SSDeepConstants.rollingWindow) &* UInt32(byte)

        h1 = h1 &+ UInt32(byte)
        h1 = h1 &- UInt32(oldByte)

        window[index] = byte
        n &+= 1

        h3 = (h3 << 5) ^ UInt32(byte)

        return h1 &+ h2 &+ h3
    }

    /// Reset the rolling hash to its initial state
    mutating func reset() {
        h1 = 0
        h2 = 0
        h3 = 0
        n = 0
        for i in 0..<SSDeepConstants.rollingWindow {
            window[i] = 0
        }
    }

    /// Get the current sum value (for testing/debugging)
    var sum: UInt32 {
        return h1 &+ h2 &+ h3
    }
}
