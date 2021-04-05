// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Mastodon
import SDWebImage
import SwiftUI
import ViewModels
import WebKit

final class AddIdentityViewController: UIViewController {
    private let viewModel: AddIdentityViewModel
    private let rootViewModel: RootViewModel
    private let displayWelcome: Bool
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let promptLabel = UILabel()
    private let urlTextField = UITextField()
    private let welcomeLabel = UILabel()
    private let instanceAndButtonsStackView = UIStackView()
    private let instanceStackView = UIStackView()
    private let instanceImageView = SDAnimatedImageView()
    private let instanceTitleLabel = UILabel()
    private let instanceURLLabel = UILabel()
    private let buttonsStackView = UIStackView()
    private let logInButton = CapsuleButton()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let joinButton = CapsuleButton()
    private let browseButton = CapsuleButton()
    private let whatIsMastodonBackgroundView = UIView()
    private let whatIsMastodonStackView = UIStackView()
    private let whatIsMastodonLabel = UILabel()
    private let whatIsMastodonVideoView: WKWebView
    private let getStartedButton = CapsuleButton()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: AddIdentityViewModel, rootViewModel: RootViewModel, displayWelcome: Bool) {
        self.viewModel = viewModel
        self.rootViewModel = rootViewModel
        self.displayWelcome = displayWelcome

        let configuration = WKWebViewConfiguration()

        configuration.allowsInlineMediaPlayback = true

        whatIsMastodonVideoView = WKWebView(frame: .zero, configuration: configuration)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        setupViewHierarchy()
        setupConstraints()
        setupViewModelBindings()
        initialDisplay()
    }
}

private extension AddIdentityViewController {
    static let verticalSpacing: CGFloat = 20
    static let whatIsMastodonVideoURL = URL(string: "https://www.youtube.com/embed/IPSbNdBmWKE?playsinline=1")!

    // swiftlint:disable:next function_body_length
    func configureViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Self.verticalSpacing
        stackView.axis = .vertical

        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeLabel.numberOfLines = 0
        welcomeLabel.textAlignment = .center
        welcomeLabel.adjustsFontForContentSizeCategory = true
        welcomeLabel.font = .preferredFont(forTextStyle: .largeTitle)
        welcomeLabel.text = NSLocalizedString("add-identity.welcome", comment: "")

        promptLabel.numberOfLines = 0
        promptLabel.textAlignment = .center
        promptLabel.adjustsFontForContentSizeCategory = true
        promptLabel.font = .preferredFont(forTextStyle: .callout)
        promptLabel.text = NSLocalizedString("add-identity.prompt", comment: "")

        urlTextField.borderStyle = .roundedRect
        urlTextField.textContentType = .URL
        urlTextField.autocapitalizationType = .none
        urlTextField.autocorrectionType = .no
        urlTextField.keyboardType = .URL
        urlTextField.placeholder = NSLocalizedString("add-identity.instance-url", comment: "")
        urlTextField.addAction(
            UIAction { [weak self] _ in self?.viewModel.urlFieldText = self?.urlTextField.text ?? "" },
            for: .editingChanged)

        instanceAndButtonsStackView.spacing = .defaultSpacing
        instanceAndButtonsStackView.distribution = .fillEqually

        instanceStackView.translatesAutoresizingMaskIntoConstraints = false
        instanceStackView.axis = .vertical
        instanceStackView.spacing = .compactSpacing
        instanceStackView.isHidden_stackViewSafe = true

        instanceTitleLabel.numberOfLines = 0
        instanceTitleLabel.textAlignment = .center
        instanceTitleLabel.adjustsFontForContentSizeCategory = true
        instanceTitleLabel.font = .preferredFont(forTextStyle: .headline)

        instanceURLLabel.numberOfLines = 0
        instanceURLLabel.textAlignment = .center
        instanceURLLabel.adjustsFontForContentSizeCategory = true
        instanceURLLabel.font = .preferredFont(forTextStyle: .subheadline)
        instanceURLLabel.textColor = .secondaryLabel

        instanceImageView.contentMode = .scaleAspectFill
        instanceImageView.layer.cornerRadius = .defaultCornerRadius
        instanceImageView.clipsToBounds = true
        instanceImageView.sd_imageIndicator = SDWebImageActivityIndicator.large

        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = .defaultSpacing

        activityIndicator.hidesWhenStopped = true

        logInButton.setTitle(NSLocalizedString("add-identity.log-in", comment: ""), for: .normal)
        logInButton.addAction(
            UIAction { [weak self] _ in
                self?.urlTextField.resignFirstResponder()
                self?.viewModel.logInTapped()
            },
            for: .touchUpInside)

        joinButton.addAction(UIAction { [weak self] _ in self?.join() }, for: .touchUpInside)
        joinButton.isHidden_stackViewSafe = true

        browseButton.setTitle(NSLocalizedString("add-identity.browse", comment: ""), for: .normal)
        browseButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.browseTapped() },
            for: .touchUpInside)
        browseButton.isHidden_stackViewSafe = true

        whatIsMastodonBackgroundView.backgroundColor = .secondarySystemBackground
        whatIsMastodonBackgroundView.clipsToBounds = true
        whatIsMastodonBackgroundView.layer.cornerRadius = .defaultCornerRadius

        whatIsMastodonStackView.translatesAutoresizingMaskIntoConstraints = false
        whatIsMastodonStackView.axis = .vertical
        whatIsMastodonStackView.spacing = .defaultSpacing * 2

        whatIsMastodonLabel.adjustsFontForContentSizeCategory = true
        whatIsMastodonLabel.font = .preferredFont(forTextStyle: .headline)
        whatIsMastodonLabel.textAlignment = .center
        whatIsMastodonLabel.text = NSLocalizedString("add-identity.what-is-mastodon", comment: "")

        getStartedButton.setTitle(NSLocalizedString("add-identity.get-started", comment: ""), for: .normal)
        getStartedButton.addAction(
            UIAction { [weak self] _ in
                self?.urlTextField.resignFirstResponder()
                self?.present(
                    UINavigationController(rootViewController: InstancePickerViewController {
                        self?.viewModel.urlFieldText = $1
                        self?.urlTextField.text = $1
                        self?.urlTextField.becomeFirstResponder()
                        self?.dismiss(animated: true)
                    }),
                    animated: true)
            },
            for: .touchUpInside)

        whatIsMastodonVideoView.scrollView.isScrollEnabled = false
        whatIsMastodonVideoView.clipsToBounds = true
        whatIsMastodonVideoView.layer.cornerRadius = .defaultCornerRadius
        whatIsMastodonVideoView.load(.init(url: Self.whatIsMastodonVideoURL))

        for button in [logInButton, joinButton, browseButton] {
            button.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }

    func setupViewHierarchy() {
        view.addSubview(welcomeLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(promptLabel)
        stackView.addArrangedSubview(urlTextField)
        stackView.addArrangedSubview(instanceAndButtonsStackView)
        instanceStackView.addArrangedSubview(instanceImageView)
        instanceStackView.addArrangedSubview(instanceTitleLabel)
        instanceStackView.addArrangedSubview(instanceURLLabel)
        instanceAndButtonsStackView.addArrangedSubview(instanceStackView)
        instanceAndButtonsStackView.addArrangedSubview(buttonsStackView)
        buttonsStackView.addArrangedSubview(activityIndicator)
        buttonsStackView.addArrangedSubview(logInButton)
        buttonsStackView.addArrangedSubview(joinButton)
        buttonsStackView.addArrangedSubview(browseButton)
        buttonsStackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(whatIsMastodonBackgroundView)
        whatIsMastodonBackgroundView.addSubview(whatIsMastodonStackView)
        whatIsMastodonStackView.addArrangedSubview(whatIsMastodonLabel)
        whatIsMastodonStackView.addArrangedSubview(whatIsMastodonVideoView)
        whatIsMastodonStackView.addArrangedSubview(getStartedButton)
    }

    func setupConstraints() {
        let instanceImageViewWidthConstraint = instanceImageView.widthAnchor.constraint(
            equalTo: instanceImageView.heightAnchor, multiplier: 16 / 9)
        instanceImageViewWidthConstraint.priority = .justBelowMax

        NSLayoutConstraint.activate([
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: .defaultSpacing),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.readableContentGuide.widthAnchor),
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            instanceImageViewWidthConstraint,
            whatIsMastodonStackView.leadingAnchor.constraint(equalTo: whatIsMastodonBackgroundView.leadingAnchor,
                                                             constant: .defaultSpacing * 2),
            whatIsMastodonStackView.topAnchor.constraint(equalTo: whatIsMastodonBackgroundView.topAnchor,
                                                         constant: .defaultSpacing * 2),
            whatIsMastodonStackView.trailingAnchor.constraint(equalTo: whatIsMastodonBackgroundView.trailingAnchor,
                                                              constant: -.defaultSpacing * 2),
            whatIsMastodonStackView.bottomAnchor.constraint(equalTo: whatIsMastodonBackgroundView.bottomAnchor,
                                                            constant: -.defaultSpacing * 2),
            whatIsMastodonVideoView.widthAnchor.constraint(equalTo: whatIsMastodonVideoView.heightAnchor,
                                                           multiplier: 16 / 9)
        ])
    }

    func setupViewModelBindings() {
        viewModel.$instance.combineLatest(viewModel.$isPublicTimelineAvailable, viewModel.$loading)
            .throttle(for: .seconds(.defaultAnimationDuration), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in self?.configure(instance: $0, isPublicTimelineAvailable: $1, loading: $2) }
            .store(in: &cancellables)

        viewModel.$alertItem
            .compactMap { $0 }
            .sink { [weak self] in self?.present(alertItem: $0) }
            .store(in: &cancellables)

        // There is a situation adding an identity from secondary navigation in which
        // setting presentingSecondaryNavigation = false on the navigation view model
        // does not work and the old secondary navigation is presented over the new
        // main navigation. This is a hack to fix it.
        rootViewModel.$navigationViewModel.dropFirst()
            .sink { [weak self] _ in self?.dismiss(animated: true) }
            .store(in: &cancellables)
    }

    func initialDisplay() {
        if displayWelcome, !UIAccessibility.isVoiceOverRunning {
            welcomeLabel.alpha = 0
            promptLabel.alpha = 0
            urlTextField.alpha = 0
            logInButton.alpha = 0
            whatIsMastodonBackgroundView.alpha = 0

            UIView.animate(withDuration: .longAnimationDuration * 2) {
                self.welcomeLabel.alpha = 1
            } completion: { _ in
                UIView.animate(withDuration: .longAnimationDuration * 2) {
                    self.welcomeLabel.alpha = 0
                } completion: { _ in
                    self.welcomeLabel.isHidden = true
                    UIView.animate(withDuration: .longAnimationDuration) {
                        self.promptLabel.alpha = 1
                    } completion: { _ in
                        UIView.animate(withDuration: .longAnimationDuration) {
                            self.urlTextField.alpha = 1
                        } completion: { _ in
                            UIView.animate(withDuration: .longAnimationDuration) {
                                self.logInButton.alpha = 1
                            } completion: { _ in
                                UIView.animate(withDuration: .longAnimationDuration) {
                                    self.whatIsMastodonBackgroundView.alpha = 1
                                } completion: { _ in
                                    self.urlTextField.becomeFirstResponder()
                                }
                            }
                        }
                    }
                }
            }
        } else {
            welcomeLabel.isHidden_stackViewSafe = true
            urlTextField.becomeFirstResponder()
        }
    }

    func configure(instance: Instance?, isPublicTimelineAvailable: Bool, loading: Bool) {
        if loading {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }

        UIView.animate(withDuration: .zeroIfReduceMotion(.defaultAnimationDuration)) {
            self.logInButton.isHidden_stackViewSafe = loading

            if let instance = instance {
                self.instanceTitleLabel.text = instance.title
                self.instanceURLLabel.text = instance.uri
                self.instanceImageView.sd_setImage(with: instance.thumbnail?.url)
                self.instanceStackView.isHidden_stackViewSafe = false

                if instance.registrations {
                    let joinButtonTitle: String

                    if instance.approvalRequired {
                        joinButtonTitle = NSLocalizedString("add-identity.request-invite", comment: "")
                    } else {
                        joinButtonTitle = NSLocalizedString("add-identity.join", comment: "")
                    }

                    self.joinButton.setTitle(joinButtonTitle, for: .normal)
                    self.joinButton.isHidden_stackViewSafe = loading
                } else {
                    self.joinButton.isHidden_stackViewSafe = true
                }

                self.browseButton.isHidden_stackViewSafe = !isPublicTimelineAvailable || loading
            } else {
                self.instanceStackView.isHidden_stackViewSafe = true
                self.joinButton.isHidden_stackViewSafe = true
                self.browseButton.isHidden_stackViewSafe = true
            }
        }
    }

    func join() {
        guard let instance = viewModel.instance, let url = viewModel.url else { return }

        let registrationViewModel = viewModel.registrationViewModel(instance: instance, url: url)
        let registrationView = RegistrationView(viewModel: registrationViewModel)
        let registrationViewController = UIHostingController(rootView: registrationView)

        show(registrationViewController, sender: self)
    }
}
