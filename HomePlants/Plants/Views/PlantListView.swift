import SwiftUI

struct PlantListView: View {
    var location: Plant.Location?
    @EnvironmentObject var store: PlantStore
    var plants: [Plant]? {
        guard let location = location else {
            return store.plants?.sortedByNextDate()
        }
        return store.plants(for: location)?.sortedByNextDate()
    }
    var hasPlants: Bool {
        guard let plants = store.plants else {
            return false
        }
        return !plants.isEmpty
    }

    init(location: Plant.Location? = nil) {
        self.location = location
    }

    var body: some View {
        content
            .navigationTitle(location?.name ?? "Pflanzen")
            .redacted(reason: store.isLoading || plants == nil ? .placeholder : [])
            .onReceive( NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification, object: nil)) { _ in
                store.load()
            }
    }

    @ViewBuilder
    var content: some View {
        if let plants = plants {
            if plants.isEmpty {
                Text("Keine Pflanzen verfügbar")
            } else {
                plantsView(plants)
            }
        } else {
            Text("Lade...")
        }
    }

    func plantsView(_ plants: [Plant]) -> some View {
        List {
            ForEach(plants, id: \.image) { plant in
                NavigationLink(
                    destination: PlantDetailView(plantID: plant.id).environmentObject(store),
                    label: {
                        PlantListViewCell(plant: plant)
                    })
            }
        }
    }
}

struct PlantListView_Previews: PreviewProvider {
    static var previews: some View {
        PlantListView(location: .bad_og).preferredColorScheme(.dark).environmentObject(PlantStore(parent: .mock))
    }
}
