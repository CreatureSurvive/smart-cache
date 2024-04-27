import Foundation

extension String: FilenameConvertible {
    public var filename: String {
        let set = CharacterSet(charactersIn: "+=/:?.")
        return components(separatedBy: set).joined()
    }
}
