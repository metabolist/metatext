// Copyright © 2021 Metabolist. All rights reserved.

import UIKit

final class OpenInDefaultBrowserActivity: UIActivity {
    private var url: URL?

    override var activityType: UIActivity.ActivityType? {
        .init(String(describing: Self.self))
    }

    override var activityTitle: String? {
        NSLocalizedString("activity.open-in-default-browser", comment: "")
    }

    override var activityImage: UIImage? {
        UIImage(systemName: "safari", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        activityItems.allSatisfy {
            guard let url = $0 as? URL else { return false }

            return UIApplication.shared.canOpenURL(url)
        }
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        url = activityItems.first { $0 is URL } as? URL
    }

    override func perform() {
        guard let url = url else { return }

        UIApplication.shared.open(url) {
            self.activityDidFinish($0)
        }
    }
}
