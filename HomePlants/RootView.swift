import SwiftUI

struct RootView: View {
    @StateObject var rootStore = RootStore()
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
