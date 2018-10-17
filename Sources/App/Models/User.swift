import FluentSQLite
import Vapor
import Authentication

final class User: Codable {

    var id: Int?
    var name: String
    var email: String
    var password: String
    var admin: Bool? = false

    var avatar: String {
        get {
            return avatarHash() ?? ""
        }
    }

    init(id: Int? = nil, name: String, email: String, password: String) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
    }

    func avatarHash() -> String? {
        do {
            return try MD5.hash(email).hexEncodedString()
        }
        catch { return "" }
    }
}

extension User: SQLiteModel { }

extension User: Migration { }

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

extension User: SessionAuthenticatable { }

extension User: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \.email
    }

    static var passwordKey: WritableKeyPath<User, String> {
        return \.password
    }
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
