import Foundation

/// Handles user customization for grid mapping, scale, and instrument.
public struct CustomizationModel: Codable {
    public var gridRows: Int
    public var gridColumns: Int
    public var scale: String
    public var instrument: String
    public var customMapping: [[UInt8]]?
    
    public static func defaultConfig() -> CustomizationModel {
        return CustomizationModel(gridRows: 4, gridColumns: 8, scale: "C Major", instrument: "Piano", customMapping: nil)
    }
    /// Load configuration from file
    public static func load(from url: URL) throws -> CustomizationModel {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CustomizationModel.self, from: data)
    }
    /// Save configuration to file
    public func save(to url: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url)
    }
} 