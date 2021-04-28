import Foundation
import Combine
import UserNotifications

class LoginStore: StoreObservableObject {
    enum AuthState {
        case unknown, authorized, unauthorized
    }
    @Published var isLoading = false
    var subscriptions = [AnyCancellable]()
    let environment: StoreEnvironment
    unowned let parent: RootStore
    @Published var isLoggedIn: AuthState = .unknown

    init(parent: RootStore) {
        self.environment = parent.environment
        self.parent = parent
        validateLogin()
    }

    func login(_ username: String, _ password: String) {
        environment.api.login(username: username, password: password)
            .replaceError(with: false)
            .map { $0 ? AuthState.authorized : AuthState.unauthorized }
            .assign(to: \.isLoggedIn, on: self)
            .store(in: &subscriptions)
    }

    func validateLogin() {
        environment
            .api
            .validateLogin()
            .map { $0 ? AuthState.authorized : AuthState.unauthorized }
            .assign(to: \.isLoggedIn, on: self)
            .store(in: &subscriptions)
    }
}
