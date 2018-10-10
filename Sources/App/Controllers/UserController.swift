import Vapor
import Leaf

final class UserController: RouteCollection {

    var pageContent = PageContent()

    func boot(router: Router) throws {
        let users = router.grouped("users")
        users.get("signup", use: new)
        users.post(User.self, at: "signup", use: create)
        users.get(use: index)
        users.get(User.parameter, use: show)
        users.patch(UserContent.self, at: User.parameter, use: update)
        users.delete(User.parameter, use: destroy)
    }

    func index(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }

    func show(_ req: Request)throws -> Future<View> {
        let user = try req.parameters.next(User.self)
        return try req.leaf().render("users/show", user)
    }

    func new(_ req: Request) throws -> Future<View> {
        pageContent.title = "Sign Up"
        //pageContent.error = "error"
        return try req.leaf().render("users/new", pageContent)
    }

    func create(_ req: Request, _ user: User) throws -> Future<Response> {
        do {
            try user.validate()
            pageContent.error = nil
            return user.create(on: req).map(to: Response.self, {
                user in return req.redirect(to: "/users/\(user.id ?? 0)")
            })
        } catch let error as ValidationError {
            print(error)
            pageContent.error = error.errorDescription
            let promise = req.eventLoop.newPromise(Response.self)
            promise.succeed(result: req.redirect(to: "signup"))
            return promise.futureResult
        }
    }

    func edit(_ req: Request) throws -> Future<View> {
        return try req.leaf().render("home", ["title": "Home"])
    }

    func update(_ req: Request, _ body: UserContent)throws -> Future<User> {
        let user = try req.parameters.next(User.self)
        return user.map(to: User.self, { user in
            user.name = body.name ?? user.name
            user.email = body.email ?? user.email
            user.password = body.password ?? user.password
            return user
        }).update(on: req)
    }

    func destroy(_ req: Request)throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).delete(on: req).transform(to: .noContent)
    }

}

struct UserContent: Content {
    var name: String?
    var email: String?
    var password: String?
}

struct PageContent: Content {
    var title: String?
    var error: String?

    init() {
        title = ""
        error = nil
    }
}
