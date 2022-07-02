// Copyright © 2021 Metabolist. All rights reserved.

import SwiftUI
import ViewModels

struct AppIconPreferencesView: View {
    @StateObject var viewModel: PreferencesViewModel

    @State var alertItem: AlertItem?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: .minimumButtonDimension)),
                GridItem(.flexible(minimum: .minimumButtonDimension)),
                GridItem(.flexible(minimum: .minimumButtonDimension))
            ]) {
                ForEach(AppIcon.allCases) {
                    cell(appIcon: $0)
                }
            }
            .padding()
        }
        .alertItem($alertItem)
        .navigationTitle("preferences.app-icon")
    }
}

private extension AppIconPreferencesView {
    @ViewBuilder func cell(appIcon: AppIcon) -> some View {
        Button {
            set(appIcon: appIcon)
        } label: {
            VStack {
                if let image = appIcon.image {
                    image
                        .cornerRadius(.defaultCornerRadius)
                        .shadow(radius: .defaultShadowRadius)
                        .padding(.compactSpacing)
                        .background(appIcon == AppIcon.current ? Color.blue : Color.clear)
                        .cornerRadius(.defaultCornerRadius)
                        .padding(.top)
                }
                Text(appIcon.nameLocalizedStringKey)
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.primary)
            }
        }
    }

    func set(appIcon: AppIcon) {
        UIApplication.shared.setAlternateIconName(appIcon.alternateIconName) { error in
            DispatchQueue.main.async {
                if let error = error {
                    alertItem = AlertItem(error: error)
                } else {
                    viewModel.objectWillChange.send()
                }
            }
        }
    }
}

enum AppIcon: String, CaseIterable {
    case classic = "AppIconClassic"
    case light = "AppIconLight"
    case rainbow = "AppIconRainbow"
    case brutalist = "AppIconBrutalist"
    case rainbowBrutalist = "AppIconRainbowBrutalist"
    case malow = "AppIconMalow"
}

extension AppIcon {
    static var current: Self? { Self(rawValue: UIApplication.shared.alternateIconName ?? Self.classic.rawValue) }

    var nameLocalizedStringKey: LocalizedStringKey {
        switch self {
        case .classic:
            return "app-icon.classic"
        case .light:
            return "app-icon.light"
        case .rainbow:
            return "app-icon.rainbow"
        case .brutalist:
            return "app-icon.brutalist"
        case .rainbowBrutalist:
            return "app-icon.rainbow-brutalist"
        case .malow:
            return "app-icon.malow"
        }
    }

    var alternateIconName: String? {
        switch self {
        case .classic:
            return nil
        default:
            return rawValue
        }
    }

    var image: Image? {
        guard let image = UIImage(named: rawValue) else { return nil }

        return Image(uiImage: image)
    }
}

extension AppIcon: Identifiable {
    var id: Self { self }
}

#if DEBUG
struct AppIconPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconPreferencesView(viewModel: .init(identityContext: .preview))
    }
}
#endif
