import Foundation

extension MemoryCache {
    public final class WrappedKey: NSObject {
        let key: Key

        public override var hash: Int { key.hashValue }

        public override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }
            return key == value.key
        }

        init(_ key: Key) {
            self.key = key
        }
    }
}
