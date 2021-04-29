//
//  PlantIntentionHandler.swift
//  Siri
//
//  Created by Christian Menschel on 29.04.21.
//

import Foundation

class GetPlantsIntentionHandler: NSObject, GetPlantsIntentHandling {
    func handle(intent: GetPlantsIntent, completion: @escaping (GetPlantsIntentResponse) -> Void) {
        completion(.success(plants: "Palme"))
    }
}
