// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class ReportViewModel: CollectionItemsViewModel {
    @Published public var elements: ReportElements
    @Published public private(set) var reportingState = ReportingState.composing

    private let accountService: AccountService
    private var cancellables = Set<AnyCancellable>()

    public init(accountService: AccountService, statusId: Status.Id? = nil, identityContext: IdentityContext) {
        self.accountService = accountService
        elements = ReportElements(accountId: accountService.account.id)

        super.init(
            collectionService: identityContext.service.navigationService.timelineService(
                timeline: .profile(accountId: accountService.account.id, profileCollection: .statusesAndReplies)),
            identityContext: identityContext)

        if let statusId = statusId {
            elements.statusIds.insert(statusId)
        }
    }

    public override func viewModel(indexPath: IndexPath) -> Any {
        let viewModel = super.viewModel(indexPath: indexPath)

        if let statusViewModel = viewModel as? StatusViewModel {
            statusViewModel.showReportSelectionToggle = true
            statusViewModel.selectedForReport = elements.statusIds.contains(statusViewModel.id)
        }

        return viewModel
    }
}

public extension ReportViewModel {
    enum ReportingState {
        case composing
        case reporting
        case done
    }

    var accountName: String { "@".appending(accountService.account.acct) }

    var accountHost: String {
        URL(string: accountService.account.url)?.host ?? ""
    }

    var isLocalAccount: Bool { accountService.isLocal }

    func report() {
        accountService.report(elements)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.reportingState = .reporting })
            .sink { [weak self] in
                guard let self = self else { return }

                switch $0 {
                case .finished:
                    self.reportingState = .done
                case let .failure(error):
                    self.alertItem = AlertItem(error: error)
                    self.reportingState = .composing
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
