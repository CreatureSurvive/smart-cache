import Foundation

public final class PersistentCache<Key: FilenameConvertible, Value: PersistentCacheValue> {
    public let cacheDirectory: URL
    public let expiration: TimeInterval

    /// Default Initializer
    /// - Parameters:
    ///   - cacheDirectory: Directory for caching. nil - user cache directory, default - nil
    ///   - expiration: The maximum age of items in the cache
    public init(cacheDirectory: URL? = nil, expiration: TimeInterval = .days(7)) {
        self.cacheDirectory = cacheDirectory ?? FileManager.default.cacheDirectory
        self.expiration = expiration
        
        FileManager.default.createDirectory(for: self.cacheDirectory)
        
        purgeExpiredItems()
    }
    
    public func purgeExpiredItems() {
        FileManager.default.purgeExpiredFiles(directory: cacheDirectory, expiration: expiration)
    }

    public var cacheSize: Int {
        let size = try? FileManager.default.directoryTotalAllocatedSize(at: cacheDirectory)
        return size ?? 0
    }
    
    public func clearCache() {
        FileManager.default.clearContentsOfDirectory(url: cacheDirectory)
    }
}

extension PersistentCache: Cache {
    public func insert(_ value: Value, forKey key: Key) throws {
        let url = fileURL(forKey: key)
        try value.cacheData().write(to: url)
    }

    public func value(forKey key: Key) throws -> Value? {
        let url = fileURL(forKey: key)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try Value(cacheData: data)
    }

    public func removeValue(forKey key: Key) throws {
        let url = fileURL(forKey: key)
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(forKey key: Key) -> URL {
        cacheDirectory.appendingPathComponent(key.filename)
    }
}

private extension FileManager {
    func clearContentsOfDirectory(url: URL) {
        DispatchQueue.global().async { [unowned self] in
            let contents = try? contentsOfDirectory(atPath: url.path)
            contents?.forEach { file in
                let fileUrl = url.appendingPathComponent(file)
                try? removeItem(atPath: fileUrl.path)
            }
        }
    }

    var cacheDirectory: URL {
        urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    func createDirectory(for url: URL) {
        var isDirectory: ObjCBool = true
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        if !exists || !isDirectory.boolValue {
            try? createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func purgeExpiredFiles(directory: URL, expiration: TimeInterval) {
        var isDirectory: ObjCBool = true
        let exists = fileExists(atPath: directory.path, isDirectory: &isDirectory)
        
        guard exists, isDirectory.boolValue else {
            return
        }
         
        let resourceKeys = Set<URLResourceKey>([.nameKey, .contentModificationDateKey, .creationDateKey])
        let enumerator = enumerator(at: directory, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!
         
        var fileURLs: [URL] = []
        for case let fileURL as URL in enumerator {
            guard
                let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                let date = resourceValues.contentModificationDate ?? resourceValues.creationDate
//                let name = resourceValues.name
            else {
                continue
            }
            
            if abs(date.timeIntervalSinceNow) > expiration {
                fileURLs.append(fileURL)
            }
        }
            
        for fileURL in fileURLs {
            do {
                try removeItem(at: fileURL)
            } catch { continue }
        }
    }
    
    /// returns total allocated size of a the directory including its subFolders or not
    func directoryTotalAllocatedSize(at url: URL, includingSubfolders: Bool = false) throws -> Int? {
        guard try isDirectoryAndReachable(at: url) else { return nil }
        if includingSubfolders {
            guard let urls = enumerator(at: url, includingPropertiesForKeys: nil)?.allObjects as? [URL] else { return nil }
            return try urls.lazy.reduce(0) {
                try ($1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
            }
        }
        return try contentsOfDirectory(at: url, includingPropertiesForKeys: nil).lazy.reduce(0) {
            try ($1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
        }
    }
    
    func isDirectoryAndReachable(at url: URL) throws -> Bool {
        guard try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            return false
        }
        return try url.checkResourceIsReachable()
    }
}

public extension TimeInterval {
    static func days(_ days: Int) -> TimeInterval {
        return TimeInterval(60*60*24*days)
    }
    
    static func hours(_ hours: Int) -> TimeInterval {
        return TimeInterval(60*60*hours)
    }
    
    static func minutes(_ minutes: Int) -> TimeInterval {
        return TimeInterval(60*minutes)
    }
    
    static func seconds(_ seconds: Int) -> TimeInterval {
        return TimeInterval(seconds)
    }
}
