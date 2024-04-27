import Foundation

public protocol PersistentCacheValue {
    init(cacheData: Data) throws
    func cacheData() throws -> Data
}

public extension PersistentCacheValue where Self: Codable {
    init(cacheData: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: cacheData)
    }

    func cacheData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
