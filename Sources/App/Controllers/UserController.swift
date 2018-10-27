import Vapor
import Crypto


final class UserController: RouteCollection {

    func boot(router: Router) throws {
        let users = router.grouped("users")
        let token = User.tokenAuthMiddleware()
        let auth = users.grouped(token)

        users.post(UserCredential.self, at: "login", use: login)
        auth.delete("logout", use: logout)

        auth.get(use: index)
        auth.get(User.parameter, use: show)
        users.post(User.self, use: create)
        auth.patch(UserPartial.self, at: User.parameter, use: update)
        auth.delete(User.parameter, use: destroy)

        auth.post("follow", User.parameter, use: follow)
        auth.post("unfollow", User.parameter, use: unfollow)
        auth.get(User.parameter, "following", use: following)
        auth.get(User.parameter, "follower", use: follower)
        auth.get("following", User.parameter, use: didFollow)

        auth.get(User.parameter, "microposts", use: posts)
        auth.get("feed", use: feeds)
    }

    func index(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }

    func show(_ req: Request) throws -> Future<UserProfile> {
        let _ = try req.requireAuthenticated(User.self)
        let user = try req.parameters.next(User.self)
        let posts = user.flatMap { try $0.microposts.query(on: req).sort(\.createAt, .descending).all() }
        let followingCount = user.flatMap { try $0.following.query(on: req).count() }
        let followerCount = user.flatMap { try $0.followers.query(on: req).count() }

        return user.and(posts).and(followingCount).and(followerCount).map { (arg0) -> UserProfile in
            let (((user, posts), followings), followers) = arg0
            let data = UserProfile(user: user, microposts: posts, followingCount: followings, followerCount: followers)
            return data
        }
    }

    func create(_ req: Request, _ user: User) throws -> Future<User.PublicUser> {
        try user.validate()
        user.password = try BCryptDigest().hash(user.password)
        return user.create(on: req).flatMap { user in
            let accessToken = try Token.createToken(forUser: user)
            return accessToken.save(on: req).map(to: User.PublicUser.self) { createdToken in
                return User.PublicUser(token: createdToken.token, user: user)
            }
        }
    }

    func update(_ req: Request, _ body: UserPartial) throws -> Future<HTTPStatus> {
        let _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap { user in
            user.name = body.name ?? user.name
            user.email = body.email ?? user.email
            user.password = (body.password != nil) ? try BCryptDigest().hash(body.password!): user.password
            try user.validate()
            return user.update(on: req).transform(to: .ok)
        }
    }

    func destroy(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        if user.admin == true {
            return try req.parameters.next(User.self).delete(on: req).transform(to: .ok)
        } else {
            return Future.map(on: req, { }).transform(to: .forbidden)
        }
    }

    func login(_ req: Request, _ body: UserCredential) throws -> Future<User.PublicUser> {
        return User.query(on: req).filter(\User.email, .equal, body.email ?? "").first().flatMap { fetchedUser in
            guard let existingUser = fetchedUser else {
                throw Abort(HTTPStatus.notFound)
            }
            let hasher = try req.make(BCryptDigest.self)
            if try hasher.verify(body.password ?? "", created: existingUser.password) {
                return try Token
                    .query(on: req)
                    .filter(\Token.userId, .equal, existingUser.requireID())
                    .delete()
                    .flatMap { _ in
                        return try Token.createToken(forUser: existingUser).save(on: req).map({ newToken -> User.PublicUser in
                            return User.PublicUser(token: newToken.token, user: existingUser)
                        })
                }
            } else {
                throw Abort(HTTPStatus.unauthorized)
            }
        }
    }

    func logout(_ req: Request) throws -> Future<HTTPResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try Token
            .query(on: req)
            .filter(\Token.userId, .equal, user.requireID())
            .delete()
            .transform(to: HTTPResponse(status: .ok))
    }

    func follow(_ req: Request) throws -> Future<HTTPResponse> {
        let currentUser = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap({ user in
            if(currentUser.id != user.id) {
                return currentUser.follow(user: user, on: req).transform(to: HTTPResponse(status: .ok))
            } else {
                throw Abort(HTTPStatus.badRequest)
            }
        })
    }

    func unfollow(_ req: Request) throws -> Future<HTTPResponse> {
        let currentUser = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap({ user in
            if(currentUser.id != user.id) {
                return currentUser.unfollow(user: user, on: req).transform(to: HTTPResponse(status: .ok))
            } else {
                throw Abort(HTTPStatus.badRequest)
            }
        })
    }

    func following(_ req: Request) throws -> Future<[User]> {
        let _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap({ user in
            return try user.following.query(on: req).all()
        })
    }

    func follower(_ req: Request) throws -> Future<[User]> {
        let _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap({ user in
            return try user.followers.query(on: req).all()
        })
    }

    func didFollow(_ req: Request) throws -> Future<UserFollowing> {
        let currentUser = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap({ user in
            return try currentUser.following.query(on: req).filter(\UserConnection.rightID, .equal, user.requireID()).count().map {
                count in return UserFollowing(didFollow: count > 0)
            }
        })
    }

    func posts(_ req: Request) throws -> Future<[Micropost]> {
        let _ = try req.requireAuthenticated(User.self)
        return try req.parameters.next(User.self).flatMap({ user in
            return try user.microposts.query(on: req).sort(\.createAt, .descending).all()
        })
    }

    func feeds(_ req: Request) throws -> Future<[UserFeed]> {
        let currentUser = try req.requireAuthenticated(User.self)
        return try currentUser.following.query(on: req).all()
            .map({ users in
                return try users.compactMap({ user -> EventLoopFuture<[UserFeed]> in
                    let microposts = try user.microposts.query(on: req).sort(\Micropost.createAt, .descending).all()
                    return microposts.map({ posts in return
                        posts.compactMap({ p in UserFeed(user: user, micropost: p) })
                    })
                })
            }).flatMap({ futurePosts in
                return EventLoopFuture<[UserFeed]>.reduce(into: [], futurePosts, eventLoop: req.eventLoop, { result, posts in
                        result += posts
                    })
            })
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

struct UserProfile: Content {
    var user: User
    var microposts: [Micropost]
    var followingCount: Int
    var followerCount: Int
}

struct UserFollowing: Content {
    var didFollow: Bool
}

struct UserFeed: Content {
    var user: User
    var micropost: Micropost
}
