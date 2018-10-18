import Vapor
import Leaf
import Crypto

final class UserController: RouteCollection {

    func boot(router: Router) throws {
        let users = router.grouped("users")
        users.get(use: index)
        users.get("signup", use: new)
        users.post(User.self, at: "signup", use: create)
        users.get("login", use: signin)
        users.post(UserCredential.self, at: "login", use: login)
        users.post("logout", use: logout)
        users.get(User.parameter, use: show)
        users.get(User.parameter, "edit", use: edit)
        users.post(UserPartial.self, at: User.parameter, "edit", use: update)
        users.post(User.parameter, "delete", use: destroy)
    }

    func index(_ req: Request) throws -> Future<View> {
        let currentUser = try req.requireAuthenticated(User.self)
        return User.query(on: req).all().flatMap { user in
            let data = AllUser(users: user, user: currentUser)
            return try req.leaf().render("users/index", data)
        }
    }

    func show(_ req: Request)throws -> Future<View> {
        let user = try req.parameters.next(User.self)
        let current = try req.requireAuthenticated(User.self)
        let posts = user.flatMap { user in
            return try user.microposts.query(on: req).sort(\.createAt, .descending).all()
        }
        return user.and(posts).flatMap { (user, posts) in
            let data = ShowUser(avatar: user.avatar,
                user: user,
                microposts: Array(posts),
                owned: (user.id == current.id))
                //followingCount: user.following.query(on: req).count(),
                //followerCount: user.followers.query(on: req).count())
            return try req.leaf().render("users/show", data)
        }
    }

    func new(_ req: Request) throws -> Future<View> {
        return try req.leaf().render("users/new")
    }

    func create(_ req: Request, _ user: User) throws -> Future<View> {
        do {
            try user.validate()
            return User.query(on: req).filter(\User.email, .equal, user.email).count().flatMap { userCount in
                if (userCount > 0) {
                    return try req.leaf().render("users/new", ["error": "email existed."])
                }
                user.password = try BCryptDigest().hash(user.password)
                return user.create(on: req).flatMap { user in
                    try req.authenticate(user)
                    let data = ShowUser(avatar: user.avatar, user: user, microposts: Array(), owned: true)
                    return try req.leaf().render("users/show", data)
                }
            }
        } catch let error as ValidationError {
            return Future.flatMap(on: req) { try req.leaf().render("users/new", ["error": error.errorDescription]) }
        }
    }

    func signin(_ req: Request) throws -> Future<View> {
        return try req.leaf().render("users/login")
    }

    func login(_ req: Request, _ body: UserCredential) throws -> Future<Response> {
        let verifier = try req.make(BCryptDigest.self)
        return User.authenticate(username: body.email ?? "", password: body.password ?? "", using: verifier, on: req).map { authedUser in
            guard let user = authedUser else {
                return req.redirect(to: "/users/signup")
            }
            try req.authenticate(user)
            return req.redirect(to: "/users/\(user.id ?? 0)")
        }
    }

    func logout(_ req: Request) throws -> Future<Response> {
        try req.unauthenticate(User.self)
        return Future.map(on: req) { return req.redirect(to: "/users/login") }
    }

    func edit(_ req: Request) throws -> Future<View> {
        guard let current = try req.authenticated(User.self) else {
            return try req.leaf().render("users/login")
        }

        let user = try req.parameters.next(User.self)

        return user.flatMap { user in
            if(current.id == user.id || (current.admin ?? false)) {
                let data = EditUser(error: nil, avatar: user.avatar, user: user)
                return try req.leaf().render("users/edit", data)
            }
            return try req.leaf().render("users/login")
        }
    }

    func update(_ req: Request, _ body: UserPartial) throws -> Future<Response> {
        do {
            let _ = try req.requireAuthenticated(User.self)
            return try req.parameters.next(User.self).flatMap({ user in
                user.name = body.name ?? user.name
                user.email = body.email ?? user.email
                user.password = (body.password != nil) ? try BCryptDigest().hash(body.password!): user.password
                try user.validate()
                return user.update(on: req).map { user in
                    req.redirect(to: "/users/\(user.id ?? 0)")
                }
            }).catchFlatMap({ error in
                guard error is ValidationError else { throw error }
                throw Abort.redirect(to: "/users/edit")
            })
        } catch {
            throw Abort.redirect(to: "users/login")
        }
    }

    func destroy(_ req: Request) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)
        if user.admin == true {
            return try req.parameters.next(User.self).delete(on: req).map({ user -> Response in
                return req.redirect(to: "/users/index")
            })
        } else {
            throw Abort.redirect(to: "/users/index")
        }
    }
}

struct UserCredential: Content {
    var email: String?
    var password: String?
}

struct UserPartial: Content {
    var name: String?
    var email: String?
    var password: String?
}

struct AllUser: Encodable {
    var users: [User]
    var user: User
}

struct EditUser: Encodable {
    var error: String?
    var avatar: String
    var user: User
}

struct ShowUser: Encodable {
    var avatar: String
    var user: User
    var microposts: [Micropost]
    var owned: Bool
    //var followingCount: Int
    //var followerCount: Int
}
