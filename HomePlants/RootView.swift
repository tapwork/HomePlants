import SwiftUI

struct RootView: View {
    @StateObject var rootStore = RootStore(environment: .live)
    @State private var showingSheet = false

    var body: some View {
        TabView {
            NavigationView {
                PlantListView()
            }.tabItem {
                Label("Planzen", systemImage: "leaf.fill")
            }
            NavigationView {
                PlantRoomListView()
            }.tabItem {
                Label("Räume", systemImage: "list.dash")
            }
        }
        .onReceive(rootStore.loginStore.$isLoggedIn) { state in
            showingSheet = state == .unauthorized
        }
        .environmentObject(rootStore.plantStore)
        .sheet(isPresented: $showingSheet) {
            LoginView(store: rootStore.loginStore)
        }
        .onAppear {
            rootStore.load()
        }
        .onContinueUserActivity("PlantIntentionIntent", perform: { userActivity in
            print(userActivity.interaction?.intent)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
