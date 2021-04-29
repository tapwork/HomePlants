import SwiftUI
import Intents

@main
struct HomePlantsApp: App {

    init() {
        setup()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                INPreferences.requestSiriAuthorization({status in
                    print(status)
                })
            }
        }
        .onChange(of: ScenePhase.active) { phase in
            print(phase)
            INPreferences.requestSiriAuthorization({status in
                print(status)
            })
        }
    }

    func setup() {
        Logger.shared = Logger(level: .warning)
    }
}
