//
//  File.swift
//  
//
//  Created by Madhanrajan Varadharajan  on 26/02/2025.
//

// File: Example/main.swift
import SwiftAPI
import Foundation

/**
 * This is a simple example application that demonstrates how to use the SwiftAPI framework.
 * It creates a basic API with two endpoints:
 * - GET /hello - Returns a greeting message
 * - POST /users - Creates a new user
 */

/**
 * Create a new instance of the App class.
 * The App class is the main entry point for creating a web application with SwiftAPI.
 */
var app = App()

/**
 * Define a route for handling GET requests to the "/hello" path.
 * This route returns a greeting message with the name provided in the query parameters,
 * or "world" if no name is provided.
 * 
 * Example: GET /hello?name=John -> {"message": "Hello, John!"}
 * Example: GET /hello -> {"message": "Hello, world!"}
 */
app.get("/hello") { request in
    // Extract the name from the query parameters, or use "world" as a default
    let name = request.query["name"] ?? "world"
    
    // Return a response with a greeting message
    return Response(body: ["message": "Hello, \(name)!"])
}

/**
 * Define a route for handling POST requests to the "/users" path.
 * This route creates a new user with the name provided in the request body.
 * It returns a 201 Created status code with the user's ID and name.
 * 
 * Example: POST /users {"name": "John"} -> {"id": "123e4567-e89b-12d3-a456-426614174000", "name": "John"}
 */
app.post("/users") { request in
    // Validate that the name is provided in the request body
    guard let name = request.body["name"] as? String else {
        // If the name is missing, return a 400 Bad Request response
        return Response(statusCode: 400, body: ["error": "Name is required"])
    }
    
    // In a real app, you would save the user to a database here
    
    // Return a 201 Created response with the user's ID and name
    return Response(statusCode: 201, body: ["id": UUID().uuidString, "name": name])
}

/**
 * Start the server and begin listening for incoming requests.
 * This method will block the current thread and enter the main run loop.
 */
app.run()
