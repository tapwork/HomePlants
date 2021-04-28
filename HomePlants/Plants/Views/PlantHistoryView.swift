import SwiftUI

struct PlantHistoryView: View {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter
    }()
    let plant: Plant
    let rhythm: Plant.Rhythm
    var history: [Date] { rhythm.last != nil ? [rhythm.last!] : [] }

    var body: some View {
        List {
            ForEach(history, id: \.debugDescription) { date in
                Text(Self.dateFormatter.string(from: date))
                    .padding()
            }
        }.navigationTitle("\(plant.name)  \(rhythm.name)")
    }
}
