//
//  Token.swift
//  App
//
//  Created by Hiep Vu on 10/20/18.
//

import FluentSQLite
import Vapor
import Authentication

final class Token: SQLiteModel {

    var id: Int?
    var token: String
    var userId: User.ID

    init(token: String, userId: User.ID) {
        self.token = token
        self.userId = userId
    }

    static func createToken(forUser user: User) throws -> Token {
        let tokenString = Helper.randomToken(withLength: 48)
        let newToken = try Token(token: tokenString, userId: user.requireID())
        return newToken
    }
}

extension Token {
    var user: Parent<Token, User> {
        return parent(\.userId)
    }
}

extension Token: BearerAuthenticatable {
    static var tokenKey: WritableKeyPath<Token, String> = \.token
}

extension Token: Authentication.Token {
    typealias UserType = User
    typealias UserIDType = User.ID
    static var userIDKey: WritableKeyPath<Token, User.ID> = \.userId
}

extension Token: Content { }

extension Token: Migration { }
