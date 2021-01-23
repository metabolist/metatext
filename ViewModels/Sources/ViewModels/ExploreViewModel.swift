// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public final class ExploreViewModel: ObservableObject {
    public let searchViewModel: SearchViewModel

    private let exploreService: ExploreService
    private let identification: Identification

    init(service: ExploreService, identification: Identification) {
        exploreService = service
        self.identification = identification
        searchViewModel = SearchViewModel(
            searchService: exploreService.searchService(),
            identification: identification)
    }
}
