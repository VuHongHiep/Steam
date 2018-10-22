import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let api = router.grouped("api")
    
    let token = User.tokenAuthMiddleware()
    let auth = api.grouped(token)
    
    // Basic "It works" example
    auth.get { req in
        return "It works!"
    }

    // Basic "Hello, world!" example
    auth.get("hello") { req in
        return "Hello, world!"
    }

    try api.register(collection: UserController())
    try auth.register(collection: MicropostController())
}
