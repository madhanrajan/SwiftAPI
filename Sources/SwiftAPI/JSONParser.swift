//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

// JSONParser.swift
import Foundation

public protocol JSONParser {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
    func encode<T: Encodable>(_ value: T) throws -> Data
}

public struct DefaultJSONParser: JSONParser {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    public init() {}
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
}
