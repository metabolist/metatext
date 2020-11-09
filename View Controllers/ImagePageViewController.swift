// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

final class ImagePageViewController: UIPageViewController {
    let imageViewControllers: [ImageViewController]

    init(initiallyVisible: AttachmentViewModel, statusViewModel: StatusViewModel) {
        imageViewControllers = statusViewModel.attachmentViewModels.map { ImageViewController(viewModel: $0) }

        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: CGFloat.defaultSpacing])

        let index = statusViewModel.attachmentViewModels.firstIndex {
            $0.attachment.id == initiallyVisible.attachment.id
        }

        setViewControllers([imageViewControllers[index ?? 0]], direction: .forward, animated: false)
    }

    init(imageURL: URL) {
        imageViewControllers = [ImageViewController(imageURL: imageURL)]

        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [.interPageSpacing: CGFloat.defaultSpacing])

        setViewControllers(imageViewControllers, direction: .forward, animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        view.backgroundColor = .secondarySystemBackground
        view.subviews.compactMap { $0 as? UIScrollView }.first?.bounces = imageViewControllers.count > 1

        navigationItem.leftBarButtonItem = .init(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.presentingViewController?.dismiss(animated: true) })

        navigationController?.barHideOnTapGestureRecognizer.addTarget(
            self,
            action: #selector(toggleDescriptionVisibility))
    }

    override var prefersStatusBarHidden: Bool { navigationController?.isNavigationBarHidden ?? false }

    override var prefersHomeIndicatorAutoHidden: Bool { navigationController?.isNavigationBarHidden ?? false }
}

extension ImagePageViewController {
    @objc func toggleDescriptionVisibility() {
        for controller in imageViewControllers {
            controller.toggleDescriptionVisibility()
        }
    }
}

extension ImagePageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let imageViewController = viewController as? ImageViewController,
            let index = imageViewControllers.firstIndex(of: imageViewController),
            index + 1 < imageViewControllers.count
        else { return nil }

        return imageViewControllers[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let imageViewController = viewController as? ImageViewController,
            let index = imageViewControllers.firstIndex(of: imageViewController),
            index > 0
        else { return nil }

        return imageViewControllers[index - 1]
    }
}
