//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

// File: Example/main.swift
import SwiftAPI
import Foundation

// Create the app
var app = App()

// Define routes
app.get("/hello") { request in
    let name = request.query["name"] ?? "world"
    return Response(body: ["message": "Hello, \(name)!"])
}

app.post("/users") { request in
    guard let name = request.body["name"] as? String else {
        return Response(statusCode: 400, body: ["error": "Name is required"])
    }
    
    // In a real app, you would save the user to a database here
    
    return Response(statusCode: 201, body: ["id": UUID().uuidString, "name": name])
}

// Run the server
app.run()
