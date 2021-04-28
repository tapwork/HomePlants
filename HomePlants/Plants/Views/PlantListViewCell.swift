import SwiftUI

struct PlantListViewCell: View {
    let plant: Plant
    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            NetworkImage(url: plant.thumbnail, placeholder: "leaf.fill")
                .frame(width: 100, height: 100, alignment: .center)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(plant.name)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .padding(.bottom, 5)
                Text(plant.location.name).font(.caption)
                nextLabel(rhythm: plant.rhythmFlower, title: "Gießen")
                nextLabel(rhythm: plant.rhythmMoisturize, title: "Befeuchten")
                nextLabel(rhythm: plant.fertilize, title: "Düngen")
            }
        }.padding()
    }

    @ViewBuilder
    func nextLabel(rhythm: Plant.Rhythm, title: String) -> some View {
        if let next = rhythm.nextEventLocalized {
            Text("\(title): \(next)").font(.caption)
                .fontWeight(fontWeight(for: rhythm))
                .foregroundColor(color(for: rhythm))
        }
        EmptyView()
    }

    func color(for rhythm: Plant.Rhythm) -> Color {
        var color = Color.primary
        if rhythm.nextEventIsOverdue {
            color = Color.red
        } else if rhythm.nextEventIsToday {
            color = Color.green
        }
        return color
    }

    func fontWeight(for rhythm: Plant.Rhythm) -> Font.Weight {
        var weight = Font.Weight.regular
        if rhythm.nextEventIsToday {
            weight = .bold
        } else if rhythm.nextEventIsOverdue {
            weight = .heavy
        }
        return weight
    }
}
