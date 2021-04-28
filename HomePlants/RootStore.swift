import Foundation
import Combine
import UserNotifications

enum StoreEnvironment {
    case live, mock
    var api: APIClient {
        switch self {
        case .live:
            return MainAPIClient()
        case .mock:
            return MockAPIClient()
        }
    }
}

protocol StoreObservableObject: ObservableObject {
    var environment: StoreEnvironment { get }
}

class RootStore: StoreObservableObject {

    let environment: StoreEnvironment
    lazy var plantStore = PlantStore(parent: self)
    lazy var loginStore = LoginStore(parent: self)

    init(environment: StoreEnvironment = .live) {
        self.environment = environment
    }

    func load() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
            if let error = error {
                error.log(category: .notification)
            }
        }
    }

    static var mock: RootStore {
        RootStore(environment: .mock)
    }
}
