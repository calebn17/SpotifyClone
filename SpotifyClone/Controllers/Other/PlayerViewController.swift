//
//  PlayerViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 3/30/22.
//

import UIKit
import SDWebImage

class PlayerViewController: UIViewController {
    
    private let controlsView = PlayerControlsView()
    
    weak var dataSource: PlayerDataSource?

    //Creating the image view for the album artwork, etc
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .systemBlue
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(imageView)
        view.addSubview(controlsView)
        controlsView.delegate = self
        configureBarButtons()
        
        //Configure this Controller using the datasource (PlaybackPresenter)
        configure()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: view.width, height: view.width)
        controlsView.frame = CGRect(x: 10, y: imageView.bottom + 10, width: view.width - 20, height: view.height - imageView.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - 15)
    }
    
    private func configure() {
        //using the PlabackPresenter as the dataSource to get the image, song name, and subtitle
        if dataSource?.imageURL != nil {
            imageView.sd_setImage(with: dataSource?.imageURL, completed: nil)
        } else {
            imageView.sd_setImage(with: dataSource?.albumImageURL, completed: nil)
        }
        controlsView.configure(with: PlayerControlsViewViewModel(title: dataSource?.songName, subtitle: dataSource?.subtitle))
        //print("This is what the PlayerViewController is getting for images: \(dataSource?.imageURL ?? "no image url")")
    }
    
    private func configureBarButtons() {
        //adding a "x" button and a "share" button that allows the user to perform certain actions
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapClose))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didTapAction))
    }
    
    @objc private func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func didTapAction() {
        // Actions
    }


}

extension PlayerViewController: PlayerControlsViewDelegate {
    func playerControlsViewDidTapPlayPauseButton(_ playerControlsView: PlayerControlsView) {
        //
    }
    
    func playerControlsViewDidTapFowardButton(_ playerControlsView: PlayerControlsView) {
        //
    }
    
    func playerControlsViewDidTapBackwardsButton(_ playerControlsView: PlayerControlsView) {
        //
    }
    
    
}
