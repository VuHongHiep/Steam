//
//  MicropostController.swift
//  App
//
//  Created by Hiep Vu on 10/16/18.
//

import Vapor
import Multipart
import Crypto

final class MicropostController: RouteCollection {

    func boot(router: Router) throws {
        let posts = router.grouped("microposts")
        posts.post(Post.self, use: create)
        posts.delete(Micropost.parameter, use: delete)
    }

    func create(_ req: Request, _ body: Post) throws -> Future<HTTPStatus> {
        let currentUser = try req.requireAuthenticated(User.self)
        let micropost = Micropost(content: body.content!, picture: "", createAt: Date(), userId: try currentUser.requireID())
        if(body.picture != nil) { micropost.picture = MicropostController.saveFile(file: body.picture!.data) }
        return micropost.save(on: req).transform(to: .ok)
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

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let currentUser = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Micropost.self).flatMap({ post -> EventLoopFuture<HTTPStatus> in
            if(post.userId == currentUser.id) {
                return post.delete(on: req).transform(to: .ok)
            } else {
                throw Abort(HTTPStatus.unauthorized)
            }
        })
    }
}

struct Post: Content {
    var content: String?
    var picture: File?
}
