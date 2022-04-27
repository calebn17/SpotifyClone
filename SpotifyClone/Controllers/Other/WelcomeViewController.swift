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
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "albums_background")
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.7
        return view
    }()
    
    private let logoImageview: UIImageView = {
        //can actually set the image and initialize the imageView like this
        let imageView = UIImageView(image: UIImage(named: "logo"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 32, weight: .semibold)
        label.text = "Listen to Millions\n of Songs on\n the Go."
        return label
    }()

//MARK: - View Loading Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Spotify"
        view.backgroundColor = .systemGreen
        //add before button so button will appear on top of the image
        view.addSubview(imageView)
        
        view.addSubview(overlayView)
        
        //adding sign in button as a subview in the welcome vc
        view.addSubview(signInButton)
        //adding an action to the sign in button
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        
        view.addSubview(logoImageview)
        view.addSubview(label)
    }
    
    //Is called right when the subviews load
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
        overlayView.frame = view.bounds
        //setting the bounds of the sign in button
        signInButton.frame = CGRect(
            x: 20,
            y: view.height - 50 - view.safeAreaInsets.bottom,
            width: view.width - 40,
            height: 50
        )
        logoImageview.frame = CGRect(x: (view.width - 180)/2, y: (view.height - 350)/2, width: 200, height: 200)
        label.frame = CGRect(x: 30, y: logoImageview.bottom + 30, width: view.width - 60, height: 150)
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
