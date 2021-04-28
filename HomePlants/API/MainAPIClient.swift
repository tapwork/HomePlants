import Foundation
import Combine

extension URLRequest {

    static func login(_ username: String, _ password: String) -> URLRequest {
        .POST("/jwt-auth/v1/token", body: .wwwForm(["username": username, "password": password]))
    }

    static func validateLogin(_ authHeader: HTTPParameter) -> URLRequest {
        .POST("/jwt-auth/v1/token/validate", header: authHeader)
    }

    static func posts(_ authHeader: HTTPParameter) -> URLRequest {
        .GET("/acf/v3/posts", queryParameter: ["per_page": "1000"], header: authHeader)
    }

    static func update(_ id: Int, json: RhythmUpdateRequest, _ authHeader: HTTPParameter) -> URLRequest {
        .POST("/wp/v2/posts/\(id)", body: .jsonEncodable(json), header: authHeader)
    }
}

protocol APIClient: class {
    func login(username: String, password: String) -> AnyPublisher<Bool, Error>
    func validateLogin() -> AnyPublisher<Bool, Never>
    func fetchPosts() -> AnyPublisher<[Plant], Error>
    func updatePlant(id: Int, request: RhythmUpdateRequest) -> AnyPublisher<Plant, Error>
}

final class MainAPIClient: APIClient {

    var securePersistence: SecurePersistence { KeychainService.shared }
    var accessToken: String { securePersistence.loginToken ?? "" }
    var authHeader: HTTPParameter { ["Authorization": "Bearer \(accessToken)"]}
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func login(username: String, password: String) -> AnyPublisher<Bool, Error> {
        session.dataTaskPublisher(for: .login(username, password))
            .map { $0.data }
            .decode(type: Token.self, decoder: JSONDecoder.shared)
            .mapError { $0.log(category: .network) }
            .receive(on: RunLoop.main)
            .map(securePersistence.save(loginToken:))
            .eraseToAnyPublisher()
    }

    func validateLogin() -> AnyPublisher<Bool, Never> {
        session.dataTaskPublisher(for: .validateLogin(authHeader))
            .map { $0.data }
            .decode(type: TokenValidator.self, decoder: JSONDecoder.shared)
            .map { $0.data.status == 200 }
            .mapError { $0.log(category: .network) }
            .replaceError(with: false)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func fetchPosts() -> AnyPublisher<[Plant], Error> {
        session.dataTaskPublisher(for: .posts(authHeader))
            .map { $0.data }
            .decode(type: [Plant].self, decoder: JSONDecoder.shared)
            .mapError { $0.log(category: .network) }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func updatePlant(id: Int, request: RhythmUpdateRequest) -> AnyPublisher<Plant, Error> {
        session.dataTaskPublisher(for: .update(id, json: request, authHeader))
            .map { $0.data }
            .decode(type: Plant.self, decoder: JSONDecoder.shared)
            .mapError { $0.log(category: .network) }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func cancel(_ completion: @escaping () -> Void) {
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

final class MockAPIClient: APIClient {

    func login(username: String, password: String) -> AnyPublisher<Bool, Error> {
        Result.success(true).publisher.eraseToAnyPublisher()
    }

    func validateLogin() -> AnyPublisher<Bool, Never> {
        Result.success(true).publisher.eraseToAnyPublisher()
    }

    func fetchPosts() -> AnyPublisher<[Plant], Error> {
        Result.success(Plant.mocks).publisher.eraseToAnyPublisher()
    }

    func updatePlant(id: Int, request: RhythmUpdateRequest) -> AnyPublisher<Plant, Error> {
        Result.success(.mock).publisher.eraseToAnyPublisher()
    }
}
