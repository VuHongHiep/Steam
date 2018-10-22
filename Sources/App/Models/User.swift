import FluentSQLite
import Vapor
import Authentication

final class User: Codable {

    var id: Int?
    var name: String
    var email: String
    var password: String
    var admin: Bool? = false

    init(id: Int? = nil, name: String, email: String, password: String) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
    }
}

extension User: SQLiteModel { }

extension User: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: conn) { (builder) in
            try addProperties(to: builder)
            builder.unique(on: \.email)
        }
    }

    static func revert(on conn: SQLiteConnection) -> Future<Void> {
        return Database.delete(self, on: conn)
    }
}

extension User: Content { }

extension User: Parameter { }

extension User: Validatable {
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.name, .count(3...))
        try validations.add(\.email, .email)
        try validations.add(\.password, .count(6...))
        return validations
    }
}

extension User: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \.email
    }

    static var passwordKey: WritableKeyPath<User, String> {
        return \.password
    }
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

struct AdminUser: SQLiteMigration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.update(User.self, on: conn) { builder in
            builder.field(for: \.admin)
        }
    }

    static func revert(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.update(User.self, on: conn) { builder in
            builder.deleteField(for: \.admin)
        }
    }
}

struct SeedUser: SQLiteMigration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        let user = User(id: nil, name: "Admin", email: "admin@seed", password: "abcd1234")
        do {
            user.password = try BCrypt.hash(user.password)
        }
        catch { user.password = "" }
        user.admin = true
        return user.save(on: conn).transform(to: ())
    }

    static func revert(on conn: SQLiteConnection) -> Future<Void> {
        return .done(on: conn)
    }
}

extension User {
    var microposts: Children<User, Micropost> {
        return children(\.userId)
    }
}

extension User {
    var following: Siblings<User, User, UserConnection> {
        return self.siblings(\UserConnection.leftID, \UserConnection.rightID)
    }

    var followers: Siblings<User, User, UserConnection> {
        return self.siblings(\UserConnection.rightID, \UserConnection.leftID)
    }

    func follow(user: User, on connection: DatabaseConnectable) -> Future<(current: User, following: User)> {
        return Future.flatMap(on: connection) {
            let pivot = try UserConnection(left: self, right: user)
            return pivot.save(on: connection).transform(to: (self, user))
        }
    }

    func unfollow(user: User, on connection: DatabaseConnectable) -> Future<(current: User, unfollowed: User)> {
        return self.following.detach(user, on: connection).transform(to: (self, user))
    }
}

extension User {
    struct PublicUser: Content {
        var token: String
        var user: User
    }
}
