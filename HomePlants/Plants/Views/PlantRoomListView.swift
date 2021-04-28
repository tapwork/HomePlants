import SwiftUI

struct PlantRoomListView: View {

    var rooms: [Plant.Location] {
        Plant.Location.allCases.sorted(by: {$0.name < $1.name})
    }

    var body: some View {
        List {
            ForEach(rooms, id: \.rawValue) { location in
                NavigationLink(
                    destination: PlantListView(location: location),
                    label: {
                        Text(location.name)
                            .padding()
                    })
            }
        }.navigationTitle("Räume")
    }
}

struct PlantRoomListView_Previews: PreviewProvider {
    static var previews: some View {
        PlantRoomListView()
    }
}
