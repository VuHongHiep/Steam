import Vapor
import Leaf

struct StaticPage: RouteCollection {
    func boot(router: Router) throws {
        router.get("home", use: home)
        router.get("help", use: help)
        router.get("about", use: about)
        router.get("contact", use: contact)
    }

    func home(_ req: Request) throws -> Future<View> {
        do {
            let user = try req.requireAuthenticated(User.self)
            return try user.microposts.query(on: req).sort(\.createAt, .descending).all().flatMap({ (posts) -> EventLoopFuture<View> in
                let data = HomeData(user: user, avatar: "",  microposts: posts, owned: true)
                return try req.leaf().render("home", data)
            })
        } catch {
            return try req.leaf().render("home")
        }
    }

    func help(_ req: Request) throws -> Future<View> {
        do {
            let user = try req.requireAuthenticated(User.self)
            return try req.leaf().render("help", ["user": user])
        } catch {
            return try req.leaf().render("help")
        }
    }

    func about(_ req: Request) throws -> Future<View> {
        do {
            let user = try req.requireAuthenticated(User.self)
            return try req.leaf().render("about", ["user": user])
        } catch {
            return try req.leaf().render("about")
        }
    }

    func contact(_ req: Request) throws -> Future<View> {
        do {
            let user = try req.requireAuthenticated(User.self)
            return try req.leaf().render("contact", ["user": user])
        } catch {
            return try req.leaf().render("contact")
        }
    }
}

extension Request {
    // leaf() ile her seferinde make fonksiyonunu yazmamak için extension içinde handle ediyoruz.
    // make() fonksiyonu request için istenen sayfayı render etmemize yardım edecek.
    func leaf() throws -> LeafRenderer {
        return try self.make(LeafRenderer.self)
    }

    func authenticatedUser() -> User? {
        do {
            return try requireAuthenticated(User.self)
        }
        catch { return nil }
    }
}

struct HomeData: Encodable {
    var user: User
    var avatar : String
    var microposts: [Micropost]
    var owned: Bool
}
