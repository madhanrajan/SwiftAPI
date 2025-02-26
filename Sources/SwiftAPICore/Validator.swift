//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

public protocol Validatable {
    func validate() throws
}

public protocol RequestValidator {
    func validate<T: Validatable>(_ value: T) throws
}

public struct ValidationError: Error, CustomStringConvertible {
    public let message: String
    
    public init(_ message: String) {
        self.message = message
    }
    
    public var description: String {
        return message
    }
}

public struct DefaultValidator: RequestValidator {
    public init() {}
    
    public func validate<T: Validatable>(_ value: T) throws {
        try value.validate()
    }
}

