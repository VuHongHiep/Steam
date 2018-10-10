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
        return try req.leaf().render("home", ["title": "Home"])
    }

    func help(_ req: Request) throws -> Future<View> {
        return try req.leaf().render("help", ["title": "Help"])
    }

    func about(_ req: Request) throws -> Future<View> {
        return try req.leaf().render("about", ["title": "About"])
    }

    func contact(_ req: Request) throws -> Future<View> {
        return try req.leaf().render("contact", ["title": "Contact"])
    }
}

extension Request {
    // leaf() ile her seferinde make fonksiyonunu yazmamak için extension içinde handle ediyoruz.
    // make() fonksiyonu request için istenen sayfayı render etmemize yardım edecek.
    func leaf() throws -> LeafRenderer {
        return try self.make(LeafRenderer.self)
    }
}
