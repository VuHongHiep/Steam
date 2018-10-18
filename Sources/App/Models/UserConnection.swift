//
//  UserConnection.swift
//  App
//
//  Created by Hiep Vu on 10/17/18.
//

import FluentSQLite
import Vapor

final class UserConnection: SQLitePivot {
    typealias Left = User
    typealias Right = User

    static var leftIDKey: WritableKeyPath<UserConnection, Int> = \.leftID
    static var rightIDKey: WritableKeyPath<UserConnection, Int> = \.rightID

    var id: Int?
    var leftID: Int
    var rightID: Int

    init(left: User, right: User) throws {
        self.leftID = left.id!
        self.rightID = right.id!
    }
}

extension UserConnection: Migration {}
