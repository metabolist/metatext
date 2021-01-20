// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class TimelinesViewController: UIPageViewController {
    private let titleView: TimelinesTitleView
    private let timelineViewControllers: [TableViewController]
    private let viewModel: NavigationViewModel
    private let rootViewModel: RootViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: NavigationViewModel, rootViewModel: RootViewModel) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel

        let timelineViewModels: [CollectionViewModel]

        if let homeTimelineViewModel = viewModel.homeTimelineViewModel {
            timelineViewModels = [
                homeTimelineViewModel,
                viewModel.localTimelineViewModel,
                viewModel.federatedTimelineViewModel]
        } else {
            timelineViewModels = [
                viewModel.localTimelineViewModel,
                viewModel.federatedTimelineViewModel]
        }

        titleView = TimelinesTitleView(
            timelines: viewModel.identification.identity.authenticated
                ? Timeline.authenticatedDefaults
                : Timeline.unauthenticatedDefaults,
            identification: viewModel.identification)

        timelineViewControllers = timelineViewModels.map {
            TableViewController(
                viewModel: $0,
                rootViewModel: rootViewModel,
                identification: viewModel.identification)
        }

        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: [.interPageSpacing: CGFloat.defaultSpacing])

        if let firstViewController = timelineViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: false)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        tabBarItem = UITabBarItem(
            title: NSLocalizedString("main-navigation.timelines", comment: ""),
            image: UIImage(systemName: "newspaper"),
            selectedImage: nil)

        navigationItem.titleView = titleView

        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "megaphone"), primaryAction: nil)

        titleView.$selectedTimeline
            .compactMap { [weak self] in self?.titleView.timelines.firstIndex(of: $0) }
            .sink { [weak self] index in
                guard let self = self,
                      let currentViewController = self.viewControllers?.first as? TableViewController,
                      let currentIndex = self.timelineViewControllers.firstIndex(of: currentViewController),
                      index != currentIndex
                else { return }

                self.setViewControllers(
                    [self.timelineViewControllers[index]],
                    direction: index > currentIndex ? .forward : .reverse,
                    animated: !UIAccessibility.isReduceMotionEnabled)
        }
        .store(in: &cancellables)
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

        let timeline = titleView.timelines[index]

        if titleView.selectedTimeline != timeline {
            titleView.selectedTimeline = timeline
        }
    }
}
