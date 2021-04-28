import Foundation

struct RhythmUpdateRequest: Codable {
    struct Fields: Codable {
        let flowerHistory: Date?
        let moisturizehistory: Date?
        let fertilizeHistory: Date?
    }
    let fields: Fields

    static func create(from plant: Plant) -> Self {
        let fields = RhythmUpdateRequest.Fields(flowerHistory: plant.rhythmFlower.last,
                                                moisturizehistory: plant.rhythmMoisturize.last,
                                                fertilizeHistory: plant.fertilize.last)
        return RhythmUpdateRequest(fields: fields)
    }
}
