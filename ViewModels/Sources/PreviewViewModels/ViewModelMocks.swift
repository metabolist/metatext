// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import HTTP
import Mastodon
import MastodonAPI
import MastodonAPIStubs
import ServiceLayer
import ServiceLayerMocks
import ViewModels

private let decoder = MastodonDecoder()
private let devInstanceURL = URL(string: "https://mastodon.social")!

// swiftlint:disable force_try
extension AppEnvironment {
    public static let mockAuthenticated: Self = .mock(
        identityFixture: .init(
            id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
            instanceURL: devInstanceURL,
            instance: try! decoder.decode(Instance.self,
                                          from: InstanceEndpoint.instance.data(url: devInstanceURL)!),
            account: try! decoder.decode(Account.self,
                                         from: AccountEndpoint.verifyCredentials.data(url: devInstanceURL)!)))
}

extension RootViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> Self {
        try! Self(environment: environment,
                  registerForRemoteNotifications: { Empty().eraseToAnyPublisher() })
    }
}
// swiftlint:enable force_try

extension AddIdentityViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> AddIdentityViewModel {
        RootViewModel.mock(environment: environment).addIdentityViewModel()
    }
}

extension TabNavigationViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> TabNavigationViewModel {
        RootViewModel.mock(environment: environment).tabNavigationViewModel!
    }
}

extension SecondaryNavigationViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> SecondaryNavigationViewModel {
        TabNavigationViewModel.mock(environment: environment)
            .secondaryNavigationViewModel()
    }
}

extension IdentitiesViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> IdentitiesViewModel {
        SecondaryNavigationViewModel.mock(environment: environment).identitiesViewModel()
    }
}

extension ListsViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> ListsViewModel {
        SecondaryNavigationViewModel.mock(environment: environment).listsViewModel()
    }
}

extension PreferencesViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> PreferencesViewModel {
        SecondaryNavigationViewModel.mock(environment: environment).preferencesViewModel()
    }
}

extension PostingReadingPreferencesViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> PostingReadingPreferencesViewModel {
        PreferencesViewModel.mock(environment: environment)
            .postingReadingPreferencesViewModel()
    }
}

extension NotificationTypesPreferencesViewModel {
    public static func mock(
        environment: AppEnvironment = .mockAuthenticated) -> NotificationTypesPreferencesViewModel {
        PreferencesViewModel.mock(environment: environment)
            .notificationTypesPreferencesViewModel()
    }
}

extension FiltersViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> FiltersViewModel {
        PreferencesViewModel.mock(environment: environment).filtersViewModel()
    }
}

extension EditFilterViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> EditFilterViewModel {
        FiltersViewModel.mock(environment: environment).editFilterViewModel(filter: .new)
    }
}

extension StatusListViewModel {
    public static func mock(environment: AppEnvironment = .mockAuthenticated) -> StatusListViewModel {
        TabNavigationViewModel.mock(environment: environment).viewModel(timeline: .home)
    }
}
