import Foundation

struct Plant: Decodable, Identifiable {

    let id: Int
    let name: String
    var rhythmFlower: Rhythm
    var rhythmMoisturize: Rhythm
    var fertilize: Rhythm
    let comment: String
    let location: Location
    let image: URL?
    var thumbnail: URL? {
        image?.appendingQueryComponent(key: "size", value: "200")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case acf
        case name
        case rhythmFlower
        case flowerHistory
        case rhythmMoisturize
        case moisturizehistory
        case fertilize
        case fertilizeHistory
        case comment
        case location
        case image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let acf = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .acf)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try acf.decode(String.self, forKey: .name)

        self.comment = try acf.decode(String.self, forKey: .comment)
        self.location = try acf.decode(Location.self, forKey: .location)
        self.image = try? acf.decode(URL.self, forKey: .image)

        let rhythmFlowerKind = try acf.decode(RhythmKind.self, forKey: .rhythmFlower)
        let flowerLast = try? acf.decode(Date.self, forKey: .flowerHistory)
        self.rhythmFlower = Rhythm(kind: rhythmFlowerKind, name: "Gießen", last: flowerLast)

        let rhythmMoisturizeKind = try acf.decode(RhythmKind.self, forKey: .rhythmMoisturize)
        let moisturizeLast = (try? acf.decode(Date.self, forKey: .moisturizehistory))
        self.rhythmMoisturize = Rhythm(kind: rhythmMoisturizeKind, name: "Befeuchten", last: moisturizeLast)

        let fertilizeKind = try acf.decode(RhythmKind.self, forKey: .fertilize)
        let fertilizeLast = try? acf.decode(Date.self, forKey: .fertilizeHistory)
        self.fertilize = Rhythm(kind: fertilizeKind, name: "Düngen", last: fertilizeLast)
    }
}

extension Plant {

    enum Location: String, Codable, CaseIterable {
        case sz_ug
        case bad_ug
        case bad_og
        case bad_guest
        case ankleide
        case flur_ug
        case flur_og
        case guest_ug
        case guest_og
        case living
        case wardrobe
    }
    enum RhythmKind: String, Codable {
        case never
        case daily
        case weekly
        case biweekly
        case monthly
        var interval: TimeInterval? {
            switch self {
            case .never: return nil
            case .daily: return 60*60*24
            case .weekly: return 60*60*24*7
            case .biweekly: return 60*60*24*7*2
            case .monthly: return 60*60*24*7*4
            }
        }
    }
    struct Rhythm: Codable {
        let kind: RhythmKind
        let name: String
        var last: Date?

        var nextEventInterval: TimeInterval? {
            guard let nextInterval = kind.interval else { return nil }
            let current = Date()
            let lastDate = last ?? current
            return max(lastDate.timeIntervalSince1970 - current.timeIntervalSince1970 + nextInterval, 0.0)
        }

        var nextEventDate: Date? {
            guard let interval = nextEventInterval else { return nil }
            return Date().addingTimeInterval(interval)
        }

        var nextEventDay: Date? {
            guard let nextEventDate = nextEventDate else { return nil }
            let cal = Calendar.current
            var components = cal.dateComponents([.year, .month, .day], from: nextEventDate)
            components.hour = 12
            components.minute = 0
            components.second = 0
            return cal.date(from: components)!
        }

        var nextEventLocalized: String? {
            guard let nextEventDate = nextEventDate else { return nil }
            if nextEventIsOverdue {
                return "Überfällig"
            }
            return RelativeDateTimeFormatter.relative(for: nextEventDate)
        }

        var nextEventIsToday: Bool {
            guard let nextEventDate = nextEventDate else { return false }
            return Calendar.current.isDateInToday(nextEventDate)
        }

        var nextEventIsOverdue: Bool {
            guard let nextEventDate = nextEventDate else { return false }
            let isToday = Calendar.current.isDateInToday(nextEventDate)
            return !isToday && nextEventDate <= Date()
        }

        var lastEventLocalized: String? {
            guard let last = last else { return nil }
            return RelativeDateTimeFormatter.relative(for: last)
        }
    }
}

extension Plant.Location {
    var name: String {
        switch self {
        case .ankleide: return "Ankleide"
        case .bad_og: return "Bad OG"
        case .bad_ug: return "Bad EG"
        case .bad_guest: return "Bad Gäste WC"
        case .flur_og: return "Flur OG"
        case .flur_ug: return "Flur EG"
        case .guest_og: return "Gästezimmer OG"
        case .guest_ug: return "Gästezimmer EG"
        case .living: return "Wohnzimmer"
        case .sz_ug: return "Schlafzimmer"
        case .wardrobe: return "Garderobe"
        }
    }
}

extension Plant.RhythmKind {
    var name: String {
        switch self {
        case .never: return "Nie"
        case .daily: return "Täglich"
        case .weekly: return "Wöchentlich"
        case .biweekly: return "2-Wöchentlich"
        case .monthly: return "Monatlich"
        }
    }
}

extension RelativeDateTimeFormatter {
    static var namedShared: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()

    static func relative(for futureDate: Date) -> String? {
        if Calendar.current.isDateInToday(futureDate) {
            return "Heute"
        }
        // we have to the equalize the times for the date to get the correct localized string
        // there is a bug inside RelativeDateTimeFormatter see: FB9080980
        // This workaround will at least fix the day comparism. but won't fix the week comparism
        let todayComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        let today = Calendar.current.date(from: todayComps)!
        var futureComps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: futureDate)
        futureComps.setValue(todayComps.hour, for: .hour)
        futureComps.setValue(todayComps.minute, for: .minute)
        let future = Calendar.current.date(from: futureComps)!
        return RelativeDateTimeFormatter.namedShared.localizedString(for: future, relativeTo: today)

    }
}

extension Collection where Element == Plant {
    func sortedByNextDate() -> [Plant] {
        sorted { (plant1, plant2) -> Bool in
            let nextYear = Date(timeIntervalSinceNow: 60*60*24*365)
            let nextFlower1 = plant1.rhythmFlower.nextEventDate ?? nextYear
            let nextFlower2 = plant2.rhythmFlower.nextEventDate ?? nextYear
            let nextMoisterize1 = plant1.rhythmMoisturize.nextEventDate ?? nextYear
            let nextMoisterize2 = plant2.rhythmMoisturize.nextEventDate ?? nextYear
            let nextFertilize1 = plant1.fertilize.nextEventDate ?? nextYear
            let nextFertilize2 = plant2.fertilize.nextEventDate ?? nextYear
            let dates1 = [nextFlower1,nextMoisterize1,nextFertilize1].sorted()
            let dates2 = [nextFlower2,nextMoisterize2,nextFertilize2].sorted()
            return dates1.first! < dates2.first!
        }
    }

    func compare(_ rhythm1: Plant.Rhythm, _ rhythm2: Plant.Rhythm) -> Bool {
        guard let next1 = rhythm1.nextEventDate, let next2 = rhythm2.nextEventDate else {
            return false
        }
        return next1 < next2
    }
}

extension Plant {
    static var mock: Self {
        return mocks.first!
    }

    static var mocks: [Self] {
        let url = Bundle.main.url(forResource: "PlantMock", withExtension: "json")
        let data = try! Data(contentsOf: url!)
        return try! JSONDecoder().decode([Plant].self, from: data)
    }
}
