import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let session = User.authSessionsMiddleware()
    let auth = router.grouped(session)
    
    // Basic "It works" example
    auth.get { req in
        return "It works!"
    }

    // Basic "Hello, world!" example
    auth.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    auth.get("todos", use: todoController.index)
    auth.post("todos", use: todoController.create)
    auth.delete("todos", Todo.parameter, use: todoController.delete)


    let staticPage = StaticPage()
    try auth.register(collection: staticPage)

    let userController = UserController()
    try auth.register(collection: userController)
}
