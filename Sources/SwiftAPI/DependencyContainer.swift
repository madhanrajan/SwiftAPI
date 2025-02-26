//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

// DependencyContainer.swift
import Foundation

public protocol DependencyContainer {
    mutating func register<T>(type: T.Type, factory: @escaping () -> T)
    func resolve<T>() -> T?
}

public extension DependencyContainer {
    mutating func register<T>(_ factory: @escaping () -> T) {
        register(type: T.self, factory: factory)
    }
}

public struct Container: DependencyContainer {
    private var factories: [String: () -> Any] = [:]
    
    public init() {}
    
    public mutating func register<T>(type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    public func resolve<T>() -> T? {
        let key = String(describing: T.self)
        return factories[key]?() as? T
    }
}
