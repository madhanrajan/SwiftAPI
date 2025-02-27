//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

/**
 * Protocol for objects that can be validated.
 * Types conforming to this protocol can have their state validated
 * to ensure they meet certain requirements.
 */
public protocol Validatable {
    /**
     * Validates the object's state.
     * - Throws: An error if validation fails
     */
    func validate() throws
}

/**
 * Protocol for validators that can validate Validatable objects.
 * This protocol defines a generic validation method that can be used
 * to validate any type that conforms to Validatable.
 */
public protocol RequestValidator {
    /**
     * Validates a Validatable object.
     * - Parameter value: The object to validate
     * - Throws: An error if validation fails
     */
    func validate<T: Validatable>(_ value: T) throws
}

/**
 * Error type for validation failures.
 * This struct represents an error that occurs during validation,
 * with a descriptive message explaining the failure.
 */
public struct ValidationError: Error, CustomStringConvertible {
    /// The error message describing the validation failure
    public let message: String
    
    /**
     * Initializes a new ValidationError with the specified message.
     * - Parameter message: The error message describing the validation failure
     */
    public init(_ message: String) {
        self.message = message
    }
    
    /**
     * Gets a string representation of the error.
     * - Returns: The error message
     */
    public var description: String {
        return message
    }
}

/**
 * Default implementation of the RequestValidator protocol.
 * This validator simply delegates to the validate method of the Validatable object.
 */
public struct DefaultValidator: RequestValidator {
    /**
     * Initializes a new DefaultValidator.
     */
    public init() {}
    
    /**
     * Validates a Validatable object by calling its validate method.
     * - Parameter value: The object to validate
     * - Throws: An error if validation fails
     */
    public func validate<T: Validatable>(_ value: T) throws {
        try value.validate()
    }
}
