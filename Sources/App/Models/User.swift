import FluentSQLite
import Vapor

final class User: Codable {

    var id: Int?
    var name: String
    var email: String
    var password: String

    init(id: Int? = nil, name: String, email: String, password: String) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
    }
}

extension User: SQLiteModel{}

extension User: Migration { }

extension User: Content { }

extension User: Parameter { }

extension User: Validatable {
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.name, .count(3...))
        return validations
    }
}
