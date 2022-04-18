//
//  AuthViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 3/30/22.
//

import UIKit
import WebKit

class AuthViewController: UIViewController, WKNavigationDelegate {
//MARK: - Setup
    //configures the web view
    private let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }()
    
    //creates the completion handler that will be true when user successfully signs in
    public var completionHandler:((Bool) -> (Void))?

//MARK: - View loading methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Sign In"
        view.backgroundColor = .systemBackground
        //so that this vc will know when the user navigates the webview
        webView.navigationDelegate = self
        //adding the webview to this vc
        view.addSubview(webView)
        //validating the signin url exists
        guard let url = AuthManager.shared.signInURL else {return}
        //load the webview with the url from AuthManager
        webView.load(URLRequest(url: url))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //when the Subviews load up, make the webview a fullscreen (or matching the bounds of the vc's view)
        webView.frame = view.bounds
    }

//MARK: - Webview methods
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url else {return}
        
        //Exchange the code for access token
        let component = URLComponents(string: url.absoluteString)
        //grabbing the code here
        guard let code = component?.queryItems?.first(where: { $0.name == "code"})?.value else {return}
        
        //hides the webview after we grab the code
        webView.isHidden = true
        
        //exchanges the code for a token and then shows the root vc which is the TabBarViewController
        //also completion handler is now -> true
        AuthManager.shared.exchangeCodeForToken(code: code) { [weak self] success in
            DispatchQueue.main.async {
                self?.navigationController?.popToRootViewController(animated: true)
                self?.completionHandler?(success)
            }
           
            
        }
    }
    

    

}
