//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

/**
 * Protocol defining JSON parsing functionality.
 * This protocol abstracts the encoding and decoding of JSON data,
 * allowing for different implementations or mocking in tests.
 */
public protocol JSONParser {
    /**
     * Decodes JSON data into a specified type.
     * - Parameters:
     *   - type: The type to decode the JSON data into
     *   - data: The JSON data to decode
     * - Returns: An instance of the specified type
     * - Throws: An error if decoding fails
     */
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
    
    /**
     * Encodes a value into JSON data.
     * - Parameter value: The value to encode
     * - Returns: The encoded JSON data
     * - Throws: An error if encoding fails
     */
    func encode<T: Encodable>(_ value: T) throws -> Data
}

/**
 * Default implementation of the JSONParser protocol.
 * This implementation uses Foundation's JSONEncoder and JSONDecoder
 * to handle JSON serialization and deserialization.
 */
public struct DefaultJSONParser: JSONParser {
    /// The JSON decoder used for decoding JSON data
    private let decoder = JSONDecoder()
    
    /// The JSON encoder used for encoding values to JSON data
    private let encoder = JSONEncoder()
    
    /**
     * Initializes a new DefaultJSONParser with default configuration.
     */
    public init() {}
    
    /**
     * Decodes JSON data into a specified type using JSONDecoder.
     * - Parameters:
     *   - type: The type to decode the JSON data into
     *   - data: The JSON data to decode
     * - Returns: An instance of the specified type
     * - Throws: An error if decoding fails
     */
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
    
    /**
     * Encodes a value into JSON data using JSONEncoder.
     * - Parameter value: The value to encode
     * - Returns: The encoded JSON data
     * - Throws: An error if encoding fails
     */
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
}
