//
//   Micropost.swift
//  App
//
//  Created by Hiep Vu on 10/16/18.
//

import FluentSQLite
import Vapor
import Authentication

final class Micropost: Codable {
    
    var id: Int?
    var content: String
    var picture: String
    var createAt: Date?
    var userId: Int
    
    init(id: Int? = nil, content: String, picture: String, createAt: Date?, userId: Int) {
        self.id = id
        self.content = content
        self.picture = picture
        self.createAt = createAt
        self.userId = userId
    }
}

extension Micropost: SQLiteModel { }

extension Micropost: Migration { }

extension Micropost: Content { }

extension Micropost: Parameter { }

extension Micropost: Validatable {
    static func validations() throws -> Validations<Micropost> {
        var validations = Validations(Micropost.self)
        // try validations.add(\.content, .countMax(80))
        return validations
    }
}

extension Micropost {
    var user: Parent<Micropost, User> {
        return parent(\.userId)
    }
}
