//
//  IntentHandler.swift
//  Siri
//
//  Created by Christian Menschel on 29.04.21.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        if intent is GetPlantsIntent {
            return GetPlantsIntentionHandler()
        }
        fatalError("Not defined")
    }
}
