// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon
import SwiftUI
import ViewModels

struct PreferencesView: View {
    @StateObject var viewModel: PreferencesViewModel
    @StateObject var identityContext: IdentityContext
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion

    init(viewModel: PreferencesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _identityContext = StateObject(wrappedValue: viewModel.identityContext)
    }

    var body: some View {
        Form {
            Section(header: Text(viewModel.identityContext.identity.handle)) {
                if viewModel.identityContext.identity.authenticated
                    && !viewModel.identityContext.identity.pending {
                    NavigationLink("preferences.filters",
                                   destination: FiltersView(
                                    viewModel: .init(identityContext: viewModel.identityContext)))
                    if viewModel.shouldShowNotificationTypePreferences {
                        NavigationLink("preferences.notification-types",
                                       destination: NotificationTypesPreferencesView(
                                        viewModel: .init(identityContext: viewModel.identityContext)))
                    }
                    Button("preferences.muted-users") {
                        rootViewModel.navigationViewModel?.navigateToMutedUsers()
                    }
                    .foregroundColor(.primary)
                    Button("preferences.blocked-users") {
                        rootViewModel.navigationViewModel?.navigateToBlockedUsers()
                    }
                    .foregroundColor(.primary)
                    NavigationLink("preferences.blocked-domains",
                                   destination: DomainBlocksView(viewModel: viewModel.domainBlocksViewModel()))
                    Toggle("preferences.use-preferences-from-server",
                           isOn: $viewModel.preferences.useServerPostingReadingPreferences)
                    Group {
                        Picker("preferences.posting-default-visibility",
                               selection: $viewModel.preferences.postingDefaultVisibility) {
                            Text("status.visibility.public").tag(Status.Visibility.public)
                            Text("status.visibility.unlisted").tag(Status.Visibility.unlisted)
                            Text("status.visibility.private").tag(Status.Visibility.private)
                        }
                        Toggle("preferences.posting-default-sensitive",
                               isOn: $viewModel.preferences.postingDefaultSensitive)
                    }
                    .disabled(viewModel.preferences.useServerPostingReadingPreferences)
                }
                Group {
                    Picker("preferences.reading-expand-media",
                           selection: $viewModel.preferences.readingExpandMedia) {
                        Text("preferences.expand-media.default").tag(Preferences.ExpandMedia.default)
                        Text("preferences.expand-media.show-all").tag(Preferences.ExpandMedia.showAll)
                        Text("preferences.expand-media.hide-all").tag(Preferences.ExpandMedia.hideAll)
                    }
                    Toggle("preferences.reading-expand-spoilers",
                           isOn: $viewModel.preferences.readingExpandSpoilers)
                }
                .disabled(viewModel.preferences.useServerPostingReadingPreferences
                            && viewModel.identityContext.identity.authenticated)
            }
            Section(header: Text("preferences.app")) {
                Group {
                    if UIApplication.shared.supportsAlternateIcons {
                        NavigationLink(destination: AppIconPreferencesView(viewModel: viewModel)) {
                            HStack {
                                Text("preferences.app-icon")
                                Spacer()
                                if let appIcon = AppIcon.current {
                                    if let image = appIcon.image {
                                        image
                                            .resizable()
                                            .frame(
                                                width: UIFont.preferredFont(forTextStyle: .body).lineHeight,
                                                height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                                            .cornerRadius(.defaultCornerRadius / 2)
                                    }
                                    Text(appIcon.nameLocalizedStringKey)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    Picker("preferences.app.color-scheme", selection: $identityContext.appPreferences.colorScheme) {
                        ForEach(AppPreferences.ColorScheme.allCases) { option in
                            Text(option.localizedStringKey).tag(option)
                        }
                    }
                    NavigationLink("preferences.notifications",
                                   destination: NotificationPreferencesView(viewModel: viewModel))
                    Picker("preferences.status-word",
                           selection: $identityContext.appPreferences.statusWord) {
                        ForEach(AppPreferences.StatusWord.allCases) { option in
                            Text(option.localizedStringKey).tag(option)
                        }
                    }
                    Toggle("preferences.show-reblog-and-favorite-counts",
                           isOn: $identityContext.appPreferences.showReblogAndFavoriteCounts)
                    Toggle("preferences.require-double-tap-to-reblog",
                           isOn: $identityContext.appPreferences.requireDoubleTapToReblog)
                    Toggle("preferences.require-double-tap-to-favorite",
                           isOn: $identityContext.appPreferences.requireDoubleTapToFavorite)
                    Toggle("preferences.links.open-in-default-browser",
                           isOn: $identityContext.appPreferences.openLinksInDefaultBrowser)
                    if !identityContext.appPreferences.openLinksInDefaultBrowser {
                        Toggle("preferences.links.use-universal-links",
                               isOn: $identityContext.appPreferences.useUniversalLinks)
                    }
                }
                Group {
                    Picker("preferences.media.autoplay.gifs",
                           selection: $identityContext.appPreferences.autoplayGIFs) {
                        ForEach(AppPreferences.Autoplay.allCases) { option in
                            Text(option.localizedStringKey).tag(option)
                        }
                    }
                    Picker("preferences.media.autoplay.videos",
                           selection: $identityContext.appPreferences.autoplayVideos) {
                        ForEach(AppPreferences.Autoplay.allCases) { option in
                            Text(option.localizedStringKey).tag(option)
                        }
                    }
                    Picker("preferences.media.avatars.animate",
                           selection: $identityContext.appPreferences.animateAvatars) {
                        ForEach(AppPreferences.AnimateAvatars.allCases) { option in
                            Text(option.localizedStringKey).tag(option)
                        }
                    }
                    Toggle("preferences.media.custom-emojis.animate",
                           isOn: $identityContext.appPreferences.animateCustomEmojis)
                    Toggle("preferences.media.headers.animate",
                           isOn: $identityContext.appPreferences.animateHeaders)
                }
                if viewModel.identityContext.identity.authenticated
                    && !viewModel.identityContext.identity.pending {
                    Picker("preferences.home-timeline-position-on-startup",
                           selection: $identityContext.appPreferences.homeTimelineBehavior) {
                        ForEach(AppPreferences.PositionBehavior.allCases) { option in
                            Text(option.localizedStringKey).tag(option)
                        }
                    }
                }
            }
        }
        .navigationTitle("preferences")
        .alertItem($viewModel.alertItem)
        .onReceive(NotificationCenter.default.publisher(
                    for: UIAccessibility.videoAutoplayStatusDidChangeNotification)) { _ in
            viewModel.objectWillChange.send()
        }
    }
}

extension AppPreferences.ColorScheme {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .system:
            return "preferences.app.color-scheme.system"
        case .light:
            return "preferences.app.color-scheme.light"
        case .dark:
            return "preferences.app.color-scheme.dark"
        }
    }
}

extension AppPreferences.StatusWord {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .toot:
            return "toot"
        case .post:
            return "post"
        }
    }
}

extension AppPreferences.AnimateAvatars {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .everywhere:
            return "preferences.media.avatars.animate.everywhere"
        case .profiles:
            return "preferences.media.avatars.animate.profiles"
        case .never:
            return "preferences.media.avatars.animate.never"
        }
    }
}

extension AppPreferences.Autoplay {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .always:
            return "preferences.media.autoplay.always"
        case .wifi:
            return "preferences.media.autoplay.wifi"
        case .never:
            return "preferences.media.autoplay.never"
        }
    }
}

extension AppPreferences.PositionBehavior {
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .localRememberPosition:
            return "preferences.position.remember-position"
        case .newest:
            return "preferences.position.newest"
        }
    }
}

#if DEBUG
import PreviewViewModels

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: .init(identityContext: .preview))
    }
}
#endif
