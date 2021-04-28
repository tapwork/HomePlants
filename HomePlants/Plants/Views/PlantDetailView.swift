import SwiftUI
import Combine

struct PlantDetailView: View {
    let plantID: Int
    var plant: Plant? { store.plant(for: plantID) }
    @EnvironmentObject var store: PlantStore

    var body: some View {
        if let plant = plant {
            content(for: plant)
        } else {
            Text("Konnte Pflanze nicht laden")
        }
    }

    func content(for plant: Plant) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                imageView(plant)
                VStack(alignment: .leading, spacing: 10) {
                    flowerView(plant)
                    moisturizeView(plant)
                    fertilizeView(plant)
                    commentView(plant)
                }.padding()
            }.padding(.bottom)
        }
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(.all, edges: .top)
    }

    func imageView(_ plant: Plant) -> some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
            if let url = plant.image {
                NetworkImage(url: url, placeholder: "leaf.fill")
            } else {
                Color.white.frame(height: 150)
            }
            Text(plant.location.name)
            .foregroundColor(Color.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .background(Color.black.opacity(0.5))
        }
    }

    func flowerView(_ plant: Plant) -> some View {
        rhythm(plant.rhythmFlower) {
            PlantHistoryView(plant: plant, rhythm: plant.rhythmFlower)
        } action: {
            store.addNewFlowered(plant: plant)
        }
    }

    func moisturizeView(_ plant: Plant) -> some View {
        rhythm(plant.rhythmMoisturize) {
            PlantHistoryView(plant: plant, rhythm: plant.rhythmMoisturize)
        } action: {
            store.addNewMoisturized(plant: plant)
        }
    }

    func fertilizeView(_ plant: Plant) -> some View {
        rhythm(plant.fertilize) {
            PlantHistoryView(plant: plant, rhythm: plant.fertilize)
        } action: {
            store.addNewFertilized(plant: plant)
        }
    }

    func commentView(_ plant: Plant) -> some View {
        VRoundedBox(spacing: 10) {
            Text(plant.comment)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    func rhythm(_ rhythm: Plant.Rhythm,
                openHistory: @escaping () -> PlantHistoryView,
                action: @escaping () -> Void) -> some View {
        if rhythm.kind == .never {
            EmptyView()
        } else {
            VRoundedBox {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        if let next = rhythm.nextEventLocalized {
                            Text(rhythm.kind.name + " " + rhythm.name.lowercased())
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text(next).font(.callout)
                            }
                        }
                        if let last = rhythm.lastEventLocalized {
                            NavigationLink(
                                destination: openHistory(),
                                label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text(last).font(.callout)
                                            .underline()
                                    }.foregroundColor(.primary)
                                })
                        }
                    }
                    Spacer()
                    Button(action: action) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 36, weight: .regular))
                    }.foregroundColor(Color.primary)
                }
            }
        }
    }
}

struct VRoundedBox<Content: View>: View {
    let content: () -> Content
    let spacing: CGFloat
    init(spacing: CGFloat = 10.0, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.spacing = spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.3))
        .cornerRadius(8)
    }
}

struct PlantDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PlantDetailView(plantID: Plant.mock.id)
                .environmentObject(PlantStore(parent: .mock))
                .preferredColorScheme(.dark)
            PlantDetailView(plantID: Plant.mock.id)
                .environmentObject(PlantStore(parent: .mock))
                .preferredColorScheme(.light)
        }
    }
}
