import Foundation

/// Sample Swift source code for testing
/// This file represents a typical Swift source file

struct SampleDataModel: Codable {
    let id: UUID
    let name: String
    let timestamp: Date
    let value: Double
    let isActive: Bool
    let tags: [String]

    init(id: UUID = UUID(), name: String, value: Double, isActive: Bool = true, tags: [String] = []) {
        self.id = id
        self.name = name
        self.timestamp = Date()
        self.value = value
        self.isActive = isActive
        self.tags = tags
    }
}

class DataProcessor {
    private var cache: [UUID: SampleDataModel] = [:]

    func process(_ data: SampleDataModel) throws {
        guard data.isActive else {
            throw DataError.inactiveData
        }

        cache[data.id] = data
        performCalculation(data.value)
    }

    private func performCalculation(_ value: Double) {
        let result = value * 2.0 + 100.0
        print("Calculation result: \(result)")
    }

    func getData(for id: UUID) -> SampleDataModel? {
        return cache[id]
    }

    func clearCache() {
        cache.removeAll()
    }
}

enum DataError: Error {
    case inactiveData
    case invalidInput
    case processingFailed(String)
}

extension DataProcessor {
    func batchProcess(_ items: [SampleDataModel]) throws {
        for item in items {
            try process(item)
        }
    }
}

// Example usage
let processor = DataProcessor()
let sample = SampleDataModel(name: "Test", value: 42.0, tags: ["important", "urgent"])
try? processor.process(sample)
