import SwiftUI

@main
struct HomePlantsApp: App {

    init() {
        setup()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    func setup() {
        Logger.shared = Logger(level: .warning)
    }
}
