//
//  OnboardingChartYourPathViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2024.

import Foundation

class OnboardingChartYourPathViewModel: ObservableObject {
    var containerViewModel: OnboardingContainerViewModel
    
    init(containerViewModel: OnboardingContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
    
    func togglePath(path: OnboardingPath) {
        if let index = containerViewModel.selectedPath.firstIndex(of: path) {
            containerViewModel.selectedPath.remove(at: index)
        } else {
            containerViewModel.selectedPath.append(path)
        }
    }
    
    func trackEvents() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(eventAction: AccountEventAction.submitGoals,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
