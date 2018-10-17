//
//  MicropostController.swift
//  App
//
//  Created by Hiep Vu on 10/16/18.
//

import Vapor
import Multipart
import Leaf
import Crypto

final class MicropostController: RouteCollection {

    func boot(router: Router) throws {
        let users = router.grouped("microposts")
        users.post(Post.self, use: create)
        users.post(Micropost.parameter, use: delete)
    }

    func create(_ req: Request, _ body: Post) throws -> Future<Response> {
        let currentUser = try req.requireAuthenticated(User.self)
        let micropost = Micropost(content: body.content, picture: "", createAt: Date(), userId: body.userId)
        micropost.picture = MicropostController.saveFile(file: body.picture)
        print(micropost.picture)
        return micropost.save(on: req).map({ (post) -> Response in
            return req.redirect(to: "/users/\(currentUser.id ?? 0)")
        })
    }

    static func saveFile(file: Data) -> String {
        let directory = DirectoryConfig.detect()
        let workPath = directory.workDir

        let name = UUID().uuidString.lowercased() + ".png"
        let imageFolder = "Public/uploads"
        let saveURL = URL(fileURLWithPath: workPath).appendingPathComponent(imageFolder, isDirectory: true).appendingPathComponent(name, isDirectory: false)

        do {
            try file.write(to: saveURL)
            return name
        } catch { return "" }
    }

    func delete(_ req: Request) throws -> Future<Response> {
        let currentUser = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Micropost.self).delete(on: req).map({ (post) -> Response in
            return req.redirect(to: "/users/\(currentUser.id ?? 0)")
        })
    }
}

struct Post: Content {
    var content: String
    var userId: Int
    var picture: Data
}
