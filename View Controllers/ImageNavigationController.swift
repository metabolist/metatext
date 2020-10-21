// Copyright © 2020 Metabolist. All rights reserved.

import UIKit

class ImageNavigationController: UINavigationController {
    private let imagePageViewController: ImagePageViewController

    init(imagePageViewController: ImagePageViewController) {
        self.imagePageViewController = imagePageViewController

        super.init(rootViewController: imagePageViewController)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hidesBarsOnTap = true
        modalPresentationStyle = .fullScreen
    }
}
