///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

import Foundation

#if os(tvOS)

import UIKit

extension DropboxClientsManager {
    /// Starts a "token" flow.
    ///
    /// This method should no longer be used.
    /// Long-lived access tokens are deprecated. See https://dropbox.tech/developers/migrating-app-permissions-and-access-tokens.
    /// Please use `authorizeFromControllerV2` instead.
    ///
    /// - Parameters:
    ///     - sharedApplication: The shared UIApplication instance in your app.
    ///     - controller: A UIViewController to present the auth flow from. This should be the top-most view controller. Reference is weakly held.
    ///     - openURL: Handler to open a URL.
    @available(
        *,
        deprecated,
        message: "This method was used for long-lived access tokens, which are now deprecated. Please use `authorizeFromControllerV2` instead."
    )
    public static func authorizeFromController(
        _ sharedApplication: UIApplication,
        controller: UIViewController?,
        openURL: @escaping ((URL) -> Void)
    ) {
        precondition(
            DropboxOAuthManager.sharedOAuthManager != nil,
            "Call `DropboxClientsManager.setupWithAppKey` or `DropboxClientsManager.setupWithTeamAppKey` before calling this method"
        )
        let sharedMobileApplication = MobileSharedApplication(sharedApplication: sharedApplication, controller: controller, openURL: openURL)
        MobileSharedApplication.sharedMobileApplication = sharedMobileApplication
        DropboxOAuthManager.sharedOAuthManager.authorizeFromSharedApplication(sharedMobileApplication)
    }

    /// Starts the OAuth 2 Authorization Code Flow with PKCE.
    ///
    /// PKCE allows "authorization code" flow without "client_secret"
    /// It enables "native application", which is ensafe to hardcode client_secret in code, to use "authorization code".
    /// PKCE is more secure than "token" flow. If authorization code is compromised during
    /// transmission, it can't be used to exchange for access token without random generated
    /// code_verifier, which is stored inside this SDK.
    ///
    /// - Parameters:
    ///     - sharedApplication: The shared UIApplication instance in your app.
    ///     - controller: A UIViewController to present the auth flow from. This should be the top-most view controller. Reference is weakly held.
    ///     - loadingStatusDelegate: An optional delegate to handle loading experience during auth flow.
    ///       e.g. Show a loading spinner and block user interaction while loading/waiting.
    ///       If a delegate is not provided, the SDK will show a default loading spinner when necessary.
    ///     - openURL: Handler to open a URL.
    ///     - scopeRequest: Contains requested scopes to obtain.
    /// - NOTE:
    ///     If auth completes successfully, A short-lived Access Token and a long-lived Refresh Token will be granted.
    ///     API calls with expired Access Token will fail with AuthError. An expired Access Token must be refreshed
    ///     in order to continue to access Dropbox APIs.
    ///
    ///     API clients set up by `DropboxClientsManager` will get token refresh logic for free.
    ///     If you need to set up `DropboxClient`/`DropboxTeamClient` without `DropboxClientsManager`,
    ///     you will have to set up the clients with an appropriate `AccessTokenProvider`.
    public static func authorizeFromControllerV2(
        _ sharedApplication: UIApplication,
        controller: UIViewController?,
        loadingStatusDelegate: LoadingStatusDelegate?,
        openURL: @escaping ((URL) -> Void),
        scopeRequest: ScopeRequest?
    ) {
        precondition(
            DropboxOAuthManager.sharedOAuthManager != nil,
            "Call `DropboxClientsManager.setupWithAppKey` or `DropboxClientsManager.setupWithTeamAppKey` before calling this method"
        )
        let sharedMobileApplication = MobileSharedApplication(sharedApplication: sharedApplication, controller: controller, openURL: openURL)
        sharedMobileApplication.loadingStatusDelegate = loadingStatusDelegate
        MobileSharedApplication.sharedMobileApplication = sharedMobileApplication
        DropboxOAuthManager.sharedOAuthManager.authorizeFromSharedApplication(sharedMobileApplication, usePKCE: true, scopeRequest: scopeRequest)
    }

    public static func setupWithAppKey(
        _ appKey: String,
        transportClient: DropboxTransportClient? = nil,
        backgroundTransportClient: DropboxTransportClient? = nil,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl(),
        includeBackgroundClient: Bool = false,
        requestsToReconnect: RequestsToReconnect? = nil
    ) {
        setupWithOAuthManager(
            appKey,
            oAuthManager: oAuthManager(appKey, secureStorageAccess: secureStorageAccess),
            transportClient: transportClient,
            backgroundTransportClient: backgroundTransportClient,
            oauthSetupIntent: .init(userKind: .single, isTeam: false, includeBackgroundClient: includeBackgroundClient),
            requestsToReconnect: requestsToReconnect
        )
    }

    public static func setupWithAppKey(
        _ appKey: String,
        sessionConfiguration: NetworkSessionConfiguration?,
        backgroundSessionConfiguration: NetworkSessionConfiguration?,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl(),
        includeBackgroundClient: Bool = false,
        requestsToReconnect: RequestsToReconnect? = nil
    ) {
        setupWithOAuthManager(
            appKey,
            oAuthManager: oAuthManager(appKey, secureStorageAccess: secureStorageAccess),
            sessionConfiguration: sessionConfiguration,
            backgroundSessionConfiguration: backgroundSessionConfiguration,
            oauthSetupIntent: .init(userKind: .single, isTeam: false, includeBackgroundClient: includeBackgroundClient),
            requestsToReconnect: requestsToReconnect
        )
    }

    public static func setupWithAppKey(
        _ appKey: String,
        backgroundSessionIdentifier: String,
        sharedContainerIdentifier: String? = nil,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl(),
        requestsToReconnect: @escaping RequestsToReconnect
    ) {
        let backgroundNetworkSessionConfiguration = NetworkSessionConfiguration.background(
            withIdentifier: backgroundSessionIdentifier,
            sharedContainerIdentifier: sharedContainerIdentifier
        )
        setupWithAppKey(
            appKey,
            sessionConfiguration: nil,
            backgroundSessionConfiguration: backgroundNetworkSessionConfiguration,
            secureStorageAccess: secureStorageAccess,
            includeBackgroundClient: true,
            requestsToReconnect: requestsToReconnect
        )
    }

    public static func setupWithAppKeyMultiUser(
        _ appKey: String,
        transportClient: DropboxTransportClient? = nil,
        backgroundTransportClient: DropboxTransportClient? = nil,
        tokenUid: String?,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl(),
        includeBackgroundClient: Bool = false,
        requestsToReconnect: RequestsToReconnect? = nil
    ) {
        setupWithOAuthManager(
            appKey,
            oAuthManager: oAuthManager(appKey, secureStorageAccess: secureStorageAccess),
            transportClient: transportClient,
            backgroundTransportClient: backgroundTransportClient,
            oauthSetupIntent: .init(userKind: .multi(tokenUid: tokenUid), isTeam: false, includeBackgroundClient: includeBackgroundClient),
            requestsToReconnect: requestsToReconnect
        )
    }

    public static func setupWithAppKeyMultiUser(
        _ appKey: String,
        sessionConfiguration: NetworkSessionConfiguration?,
        backgroundSessionConfiguration: NetworkSessionConfiguration?,
        tokenUid: String?,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl(),
        includeBackgroundClient: Bool = false,
        requestsToReconnect: RequestsToReconnect? = nil
    ) {
        setupWithOAuthManager(
            appKey,
            oAuthManager: oAuthManager(appKey, secureStorageAccess: secureStorageAccess),
            sessionConfiguration: sessionConfiguration,
            backgroundSessionConfiguration: backgroundSessionConfiguration,
            oauthSetupIntent: .init(userKind: .multi(tokenUid: tokenUid), isTeam: false, includeBackgroundClient: includeBackgroundClient),
            requestsToReconnect: requestsToReconnect
        )
    }

    public static func setupWithAppKeyMultiUser(
        _ appKey: String,
        backgroundSessionIdentifier: String,
        sharedContainerIdentifier: String? = nil,
        tokenUid: String?,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl(),
        requestsToReconnect: @escaping RequestsToReconnect
    ) {
        let backgroundNetworkSessionConfiguration = NetworkSessionConfiguration.background(
            withIdentifier: backgroundSessionIdentifier,
            sharedContainerIdentifier: sharedContainerIdentifier
        )
        setupWithAppKeyMultiUser(
            appKey,
            sessionConfiguration: nil,
            backgroundSessionConfiguration: backgroundNetworkSessionConfiguration,
            tokenUid: tokenUid,
            secureStorageAccess: secureStorageAccess,
            includeBackgroundClient: true,
            requestsToReconnect: requestsToReconnect
        )
    }

    public static func setupWithTeamAppKey(
        _ appKey: String,
        transportClient: DropboxTransportClient? = nil,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl()
    ) {
        setupWithOAuthManager(
            appKey,
            oAuthManager: oAuthManager(appKey, secureStorageAccess: secureStorageAccess),
            transportClient: transportClient,
            backgroundTransportClient: nil,
            oauthSetupIntent: .init(userKind: .single, isTeam: true, includeBackgroundClient: false)
        )
    }

    public static func setupWithTeamAppKey(
        _ appKey: String,
        sessionConfiguration: NetworkSessionConfiguration?,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl()
    ) {
        setupWithOAuthManager(
            appKey,
            oAuthManager: oAuthManager(appKey, secureStorageAccess: secureStorageAccess),
            sessionConfiguration: sessionConfiguration,
            oauthSetupIntent: .init(userKind: .single, isTeam: true, includeBackgroundClient: false)
        )
    }

    public static func setupWithTeamAppKeyMultiUser(
        _ appKey: String,
        transportClient: DropboxTransportClient? = nil,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl(),
        tokenUid: String?
    ) {
        setupWithOAuthManager(
            appKey,
            oAuthManager: oAuthManager(appKey, secureStorageAccess: secureStorageAccess),
            transportClient: transportClient,
            backgroundTransportClient: nil,
            oauthSetupIntent: .init(userKind: .multi(tokenUid: tokenUid), isTeam: true, includeBackgroundClient: false)
        )
    }

    public static func setupWithTeamAppKeyMultiUser(
        _ appKey: String,
        sessionConfiguration: NetworkSessionConfiguration?,
        secureStorageAccess: SecureStorageAccess = SecureStorageAccessDefaultImpl(),
        tokenUid: String?
    ) {
        setupWithOAuthManager(
            appKey,
            oAuthManager: oAuthManager(appKey, secureStorageAccess: secureStorageAccess),
            sessionConfiguration: sessionConfiguration,
            oauthSetupIntent: .init(userKind: .multi(tokenUid: tokenUid), isTeam: true, includeBackgroundClient: false)
        )
    }

    public static func oAuthManager(_ appKey: String, secureStorageAccess: SecureStorageAccess) -> DropboxMobileOAuthManager {
        .init(appKey: appKey, secureStorageAccess: secureStorageAccess, dismissSharedAppAuthController: {
            if let sharedMobileApplication = MobileSharedApplication.sharedMobileApplication {
                sharedMobileApplication.dismissAuthController()
            }
        })
    }
}

public class MobileSharedApplication: SharedApplication {
    public static var sharedMobileApplication: MobileSharedApplication?

    let sharedApplication: UIApplication
    weak var controller: UIViewController?
    let openURL: (URL) -> Void

    weak var loadingStatusDelegate: LoadingStatusDelegate?

    public init(sharedApplication: UIApplication, controller: UIViewController?, openURL: @escaping ((URL) -> Void)) {
        // fields saved for app-extension safety
        self.sharedApplication = sharedApplication
        self.openURL = openURL

        if let controller = controller {
            self.controller = controller
        } else {
            if #available(iOS 13, tvOS 13.0, *) {
                self.controller = sharedApplication.findKeyWindow()?.rootViewController
            } else {
                self.controller = sharedApplication.keyWindow?.rootViewController
            }
        }
    }

    public func presentErrorMessage(_ message: String, title: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        if let controller = controller {
            controller.present(alertController, animated: true, completion: { fatalError(message) })
        }
    }

    public func presentErrorMessageWithHandlers(_ message: String, title: String, buttonHandlers: [String: () -> Void]) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            if let handler = buttonHandlers["Cancel"] {
                handler()
            }
        })

        alertController.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            if let handler = buttonHandlers["Retry"] {
                handler()
            }
        })

        if let controller = controller {
            controller.present(alertController, animated: true, completion: {})
        }
    }

    public func presentPlatformSpecificAuth(_ authURL: URL) -> Bool {
        presentExternalApp(authURL)
        return true
    }

    public func presentAuthChannel(_ authURL: URL, tryIntercept: @escaping ((URL) -> Bool), cancelHandler: @escaping (() -> Void)) {
    }

    public func presentExternalApp(_ url: URL) {
        openURL(url)
    }

    public func canPresentExternalApp(_ url: URL) -> Bool {
        sharedApplication.canOpenURL(url)
    }

    public func dismissAuthController() {
    }

    public func presentLoading() {
        if isWebOAuthFlow {
            presentLoadingInWeb()
        } else {
            presentLoadingInApp()
        }
    }

    public func dismissLoading() {
        if isWebOAuthFlow {
            dismissLoadingInWeb()
        } else {
            dismissLoadingInApp()
        }
    }

    private var isWebOAuthFlow: Bool {
        false
    }

    /// Web OAuth flow, present the spinner over the MobileSafariViewController.
    private func presentLoadingInWeb() {
//        let safariViewController = controller?.presentedViewController as? MobileSafariViewController
//        let loadingVC = LoadingViewController(nibName: nil, bundle: nil)
//        loadingVC.modalPresentationStyle = .overFullScreen
//        safariViewController?.present(loadingVC, animated: false)
        
        NSLog("Web OAuth flow is not supported yet.")
    }

    // Web OAuth flow, dismiss loading view on the MobileSafariViewController.
    private func dismissLoadingInWeb() {
    }

    /// Delegate to app to present loading if delegate is set.
    /// Otherwise, present the spinner in the view controller.
    private func presentLoadingInApp() {
        if let loadingStatusDelegate = loadingStatusDelegate {
            loadingStatusDelegate.showLoading()
        } else {
            let loadingVC = LoadingViewController(nibName: nil, bundle: nil)
            loadingVC.modalPresentationStyle = .overFullScreen
            controller?.present(loadingVC, animated: false)
        }
    }

    /// Delegate to app to dismiss loading if delegate is set.
    /// Otherwise, dismiss the spinner in the view controller.
    private func dismissLoadingInApp() {
        if let loadingStatusDelegate = loadingStatusDelegate {
            loadingStatusDelegate.dismissLoading()
        } else if let loadingView = controller?.presentedViewController as? LoadingViewController {
            loadingView.dismiss(animated: false)
        }
    }
}

public class TVSafariViewController {
    var cancelHandler: (() -> Void) = {}

    public init(url: URL, cancelHandler: @escaping (() -> Void)) {
        self.cancelHandler = cancelHandler
    }
}

#endif
