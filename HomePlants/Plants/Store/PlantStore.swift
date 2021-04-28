import Foundation
import Combine
import UserNotifications

class PlantStore: StoreObservableObject {
    @Published var plants: [Plant]?
    @Published var isLoading = false
    @Published var isLaunching = true
    var subscriptions = [AnyCancellable]()
    unowned let parent: RootStore
    let environment: StoreEnvironment

    init(parent: RootStore) {
        self.parent = parent
        self.environment = parent.environment
        parent.loginStore.$isLoggedIn.sink { state in
            if state == .authorized {
                self.load()
            }
        }.store(in: &subscriptions)
    }

    func load() {
        isLoading = true
        environment.api.fetchPosts()
            .replaceError(with: [])
            .map(updateLocalNotifications)
            .map {plants in self.isLoading = false; return plants}
            .assign(to: \.plants, on: self)
            .store(in: &subscriptions)
    }

    func plants(for location: Plant.Location) -> [Plant]? {
        plants?.filter {$0.location == location }
    }

    func plant(for id: Int) -> Plant? {
        plants?.first(where: { $0.id == id })
    }

    func addNewFlowered(plant: Plant) {
        var copy = plant
        copy.rhythmFlower.last = Date()
        updateHistory(plant: copy)
    }

    func addNewMoisturized(plant: Plant) {
        var copy = plant
        copy.rhythmMoisturize.last = Date()
        updateHistory(plant: copy)
    }
    
    func addNewFertilized(plant: Plant) {
        var copy = plant
        copy.fertilize.last = Date()
        updateHistory(plant: copy)
    }

    func updateHistory(plant: Plant) {
        if let index = plants?.firstIndex(where: {$0.id == plant.id}) {
            plants?[index] = plant
        }
        environment
            .api
            .updatePlant(id: plant.id, request: RhythmUpdateRequest.create(from: plant))
            .sink {[weak self] _ in
            self?.load()
        } receiveValue: { (_) in}
        .store(in: &subscriptions)
    }

    func updateLocalNotifications(_ plants: [Plant]) -> [Plant] {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        plants
            .compactMap {$0.rhythmFlower.nextEventDay}
            .futureDates()
            .forEach {
                triggerLocalNotification($0, text: "Heute bitte gießen")
            }
        plants
            .compactMap {$0.rhythmMoisturize.nextEventDay}
            .futureDates()
            .forEach {
                triggerLocalNotification($0, text: "Heute bitte befeuchten")
            }
        plants
            .compactMap {$0.fertilize.nextEventDay}
            .futureDates()
            .forEach {
                triggerLocalNotification($0, text: "Heute bitte düngen")
            }
        return plants
    }

    func triggerLocalNotification(_ date: Date, text: String) {
        let content = UNMutableNotificationContent()
        content.title = "Erinnerung"
        content.body = text
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: date.description, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) {
            if let error = $0 {
                error.log(category: .notification)
            }
        }
    }
}

extension Collection where Element == Date {
    func futureDates() -> Array<Date> {
        filter {$0.distance(to: Date()) < 0}
        .distincted()
        .sorted()
    }
}

extension Collection where Element: Hashable {
    func distincted() -> Array<Element> {
        return Array(Set(self))
    }
}
