// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public final class ExploreViewModel: ObservableObject {
    public let searchViewModel: SearchViewModel
    public let identityContext: IdentityContext

    private let exploreService: ExploreService

    init(service: ExploreService, identityContext: IdentityContext) {
        exploreService = service
        self.identityContext = identityContext
        searchViewModel = SearchViewModel(
            searchService: exploreService.searchService(),
            identityContext: identityContext)
    }
}
