import Foundation

public final class SmartCache<Key: Hashable & FilenameConvertible, Value: PersistentCacheValue> {
    public var memoryCache: MemoryCache<Key, Value>
    public var persistentCache: PersistentCache<Key, Value>

    /// Default Initializer
    /// - Parameters:
    ///   - lifetime: Time in seconds. nil - unlimited, default - nil
    ///   - maximumCachedValues: Amount of elements to be stored. 0 == unlimited, default - unlimited
    ///   - totalCostLimit: The maximum total cost that the cache can hold before it starts evicting objects.
    ///   - cacheDirectory: URL for storing cache files. Default = System cache directory
    ///   - expiration: The maximum age of items in the cache
    public init(lifetime: TimeInterval? = nil, maximumCachedValues: Int = 0, totalCostLimit: Int = 100, cacheDirectory: URL? = nil, expiration: TimeInterval = .days(7)) {
        self.memoryCache = .init(lifetime: lifetime, maximumCachedValues: maximumCachedValues, totalCostLimit: totalCostLimit)
        self.persistentCache = .init(cacheDirectory: cacheDirectory, expiration: expiration)
    }
}

extension SmartCache: Cache {
    public func insert(_ value: Value, forKey key: Key) throws {
        memoryCache[key] = value
        persistentCache[key] = value
    }

    public func value(forKey key: Key) throws -> Value? {
        if let memoryEntry = memoryCache[key] {
            return memoryEntry
        } else if let persistentEntry = persistentCache[key] {
            memoryCache[key] = persistentEntry
            return persistentEntry
        } else {
            return nil
        }
    }

    public func removeValue(forKey key: Key) throws {
        memoryCache[key] = nil
        persistentCache[key] = nil
    }
}
