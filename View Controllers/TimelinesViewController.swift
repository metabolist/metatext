// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class TimelinesViewController: UIPageViewController {
    private let segmentedControl = UISegmentedControl()
    private let timelineViewControllers: [TableViewController]
    private let viewModel: NavigationViewModel
    private let rootViewModel: RootViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: NavigationViewModel, rootViewModel: RootViewModel) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel

        var timelineViewControllers = [TableViewController]()

        for (index, timeline) in viewModel.timelines.enumerated() {
            timelineViewControllers.append(
                TableViewController(
                    viewModel: viewModel.viewModel(timeline: timeline),
                    rootViewModel: rootViewModel))
            segmentedControl.insertSegment(withTitle: timeline.title, at: index, animated: false)
        }

        self.timelineViewControllers = timelineViewControllers

        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: [.interPageSpacing: CGFloat.defaultSpacing])

        if let firstViewController = timelineViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: false)
        }

        tabBarItem = UITabBarItem(
            title: NSLocalizedString("main-navigation.timelines", comment: ""),
            image: UIImage(systemName: "newspaper"),
            selectedImage: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        navigationItem.titleView = segmentedControl
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addAction(
            UIAction { [weak self] _ in
                guard let self = self,
                      let currentViewController = self.viewControllers?.first as? TableViewController,
                      let currentIndex = self.timelineViewControllers.firstIndex(of: currentViewController),
                      self.segmentedControl.selectedSegmentIndex != currentIndex
                else { return }

                self.setViewControllers(
                    [self.timelineViewControllers[self.segmentedControl.selectedSegmentIndex]],
                    direction: self.segmentedControl.selectedSegmentIndex > currentIndex ? .forward : .reverse,
                    animated: !UIAccessibility.isReduceMotionEnabled)
            },
            for: .valueChanged)
    }
}

extension TimelinesViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let timelineViewController = viewController as? TableViewController,
            let index = timelineViewControllers.firstIndex(of: timelineViewController),
            index + 1 < timelineViewControllers.count
        else { return nil }

        return timelineViewControllers[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let timelineViewController = viewController as? TableViewController,
            let index = timelineViewControllers.firstIndex(of: timelineViewController),
            index > 0
        else { return nil }

        return timelineViewControllers[index - 1]
    }
}

extension TimelinesViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard let viewController = viewControllers?.first as? TableViewController,
              let index = timelineViewControllers.firstIndex(of: viewController)
        else { return }

        segmentedControl.selectedSegmentIndex = index
    }
}

extension TimelinesViewController: ScrollableToTop {
    func scrollToTop(animated: Bool) {
        (viewControllers?.first as? TableViewController)?.scrollToTop(animated: animated)
    }
}
