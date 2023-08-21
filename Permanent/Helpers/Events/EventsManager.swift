//
//  EventsManager.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.08.2023.

import Foundation
import Mixpanel

struct EventsManager {
    
    static func startTracker() {
        Mixpanel.initialize(token: mixpanelServiceInfo.token, trackAutomaticEvents: true)
    }
    
    static func trackEvent(event: EventType, properties: [String: any MixpanelType]? = nil) {
        Mixpanel.mainInstance().track(event: event.rawValue,
                                      properties: properties)
    }
    
    static func setUserProfile(id: Int? = nil, email: String? = nil) {
        if let id = id {
            Mixpanel.mainInstance().identify(distinctId: String(id))
        }
        if let email = email {
            Mixpanel.mainInstance().people.set(properties: [ "$email": email])
        }
    }
    
    static func resetUser() {
        Mixpanel.mainInstance().reset()
    }
}
