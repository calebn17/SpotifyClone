//
//  WelcomeViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 3/30/22.
//

import UIKit

class WelcomeViewController: UIViewController {

//MARK: - Setup
    
    //setting the sign in button
    private let signInButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.setTitle("Sign In with Spotify", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()

//MARK: - View Loading Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Spotify"
        view.backgroundColor = .systemGreen
        
        //adding sign in button as a subview in the welcome vc
        view.addSubview(signInButton)
        //adding an action to the sign in button
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
    }
    
    //Is called right when the subviews load
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //setting the bounds of the sign in button
        signInButton.frame = CGRect(
            x: 20,
            y: view.height - 50 - view.safeAreaInsets.bottom,
            width: view.width - 40,
            height: 50
        )
    }

//MARK: - Sign in Methods
    
    @objc func didTapSignIn() {
        let vc = AuthViewController()
        
        //if the AuthViewController's completion handler is true...
        vc.completionHandler = { [weak self] success in
            DispatchQueue.main.async {
                //...then let's execute this
                self?.handleSignIn(success: success)
            }
        }
        
        //the title of the AuthViewController in the tab bar
        vc.navigationItem.largeTitleDisplayMode = .never
        //push the AuthViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func handleSignIn(success: Bool) {
        //Log user in or throw error as a dismissable alert
        guard success else {
            let alert = UIAlertController(title: "Oops", message: "Something went wrong when signing in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alert, animated: true)
            return
        }
        
        //when the user signs in successfully, then show the tab bar
        let mainAppTabBarVC = TabBarViewController()
        mainAppTabBarVC.modalPresentationStyle = .fullScreen
        present(mainAppTabBarVC, animated: true)
    }
    


}
