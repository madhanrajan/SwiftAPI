//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

import Foundation

/**
 * Protocol defining a dependency injection container.
 * A dependency container is responsible for registering and resolving dependencies
 * in the application, enabling loose coupling between components.
 */
public protocol DependencyContainer {
    /**
     * Registers a factory function for creating instances of a specific type.
     * - Parameters:
     *   - type: The type to register
     *   - factory: A function that creates an instance of the specified type
     */
    mutating func register<T>(type: T.Type, factory: @escaping () -> T)
    
    /**
     * Resolves a dependency of the specified type.
     * - Returns: An instance of the requested type, or nil if the type is not registered
     */
    func resolve<T>() -> T?
}

/**
 * Extension to DependencyContainer that provides a convenience method for registering dependencies.
 * This method infers the type from the factory function's return type.
 */
public extension DependencyContainer {
    /**
     * Registers a factory function for creating instances, inferring the type from the return type.
     * - Parameter factory: A function that creates an instance of a type
     */
    mutating func register<T>(_ factory: @escaping () -> T) {
        register(type: T.self, factory: factory)
    }
}

/**
 * A concrete implementation of the DependencyContainer protocol.
 * This container stores factory functions for different types and provides
 * methods to register and resolve dependencies.
 */
public struct Container: DependencyContainer {
    /// Dictionary mapping type names to factory functions
    private var factories: [String: () -> Any] = [:]
    
    /**
     * Initializes a new empty container.
     */
    public init() {}
    
    /**
     * Registers a factory function for creating instances of a specific type.
     * - Parameters:
     *   - type: The type to register
     *   - factory: A function that creates an instance of the specified type
     */
    public mutating func register<T>(type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /**
     * Resolves a dependency of the specified type.
     * - Returns: An instance of the requested type, or nil if the type is not registered
     */
    public func resolve<T>() -> T? {
        let key = String(describing: T.self)
        return factories[key]?() as? T
    }
}
