//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

// RequestValidator.swift
import Foundation

public protocol Validatable {
    func validate() throws
}

public protocol RequestValidator {
    func validate<T: Validatable>(_ value: T) throws
}

public struct ValidationError: Error {
    let message: String
}

public struct DefaultValidator: RequestValidator {
    public init() {}
    
    public func validate<T: Validatable>(_ value: T) throws {
        try value.validate()
    }
}
