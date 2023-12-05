//
//  EventsManager.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.08.2023.

import Foundation
import Mixpanel

struct EventsManager {
    
    static func startTracker(token: String) {
        Mixpanel.initialize(token: token, trackAutomaticEvents: true)
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
    
    static func trackPageView(page: EventPage) {
        Mixpanel.mainInstance().track(event: "Screen View", properties: ["page" : page.rawValue])
    }
    
    
    static func resetUser() {
        Mixpanel.mainInstance().reset()
    }
}
