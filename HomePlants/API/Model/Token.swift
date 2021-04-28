import Foundation

struct Token: Codable {
    let token: String
    let userEmail: String
    let userNicename: String
    let userDisplayName: String
}

struct TokenValidator: Codable {
    struct Result: Codable {
        let status: Int
    }
    let code: String
    let data: Result
}
