import SwiftUI

/// Presents a survey webview to the window's root
final class PresentSurveyManager {
    init() {
        /*
         This empty initializer prevents external instantiation of the PresentSurveyManager class.
         The class serves as a namespace for the present method, so instance creation is not needed and should be restricted.
        */
    }
    
    /// The view controller that will present the survey window.
    private weak var viewController: UIViewController?

    /// Finds the topmost view controller in the hierarchy to present from
    private func topViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = viewController as? UINavigationController {
            return topViewController(from: navigation.visibleViewController ?? navigation)
        }
        if let tabBar = viewController as? UITabBarController {
            return topViewController(from: tabBar.selectedViewController ?? tabBar)
        }
        return viewController
    }

    /// Present the webview
    /// The native background is always `.clear` — overlay rendering is handled
    /// entirely by the JS survey library inside the WebView to avoid double-overlay artifacts.
    func present(environmentResponse: EnvironmentResponse, id: String, completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let window = UIApplication.safeKeyWindow,
                  let rootVC = window.rootViewController else {
                completion?(false)
                return
            }

            // Determine the presenter: use root if available, otherwise find topmost
            let presenter: UIViewController
            if rootVC.presentedViewController == nil {
                // Root is free, use it directly (simple path)
                presenter = rootVC
            } else {
                // Root is already presenting, find the topmost view controller
                presenter = self.topViewController(from: rootVC)
            }

            // Check if presenter is already presenting
            guard presenter.presentedViewController == nil else {
                completion?(false)
                return
            }

            let view = FormbricksView(viewModel: FormbricksViewModel(environmentResponse: environmentResponse, surveyId: id))
            let vc = UIHostingController(rootView: view)
            vc.modalPresentationStyle = .overCurrentContext
            vc.view.backgroundColor = .clear
            if let presentationController = vc.presentationController as? UISheetPresentationController {
                presentationController.detents = [.large()]
            }
            self.viewController = vc
            presenter.present(vc, animated: true, completion: {
                completion?(true)
            })
        }
    }
    
    /// Dismiss the webview
    func dismissView() {
        viewController?.dismiss(animated: true)
    }
    
    deinit {
        Formbricks.logger?.debug("Deinitializing \(self)")
    }
}
