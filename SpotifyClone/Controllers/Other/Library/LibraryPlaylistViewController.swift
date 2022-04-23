//
//  LibraryPlaylistViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/23/22.
//

import UIKit

class LibraryPlaylistViewController: UIViewController {

    var playlists: [Playlist] = []
    
    private let noPlaylistsView = ActionLabelView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpNoPlaylistsView()
        fetchCurrentPlaylists()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noPlaylistsView.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        noPlaylistsView.center = view.center
       
    }
    
    private func fetchCurrentPlaylists() {
        APICaller.shared.getCurrentUserPlaylists { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let playlists):
                    self?.playlists = playlists
                    self?.updateUI()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private func setUpNoPlaylistsView() {
        noPlaylistsView.configure(with: ActionLabelViewViewModel(text: "You don't have any playlists yet", actionTitle: "Create"))
        view.addSubview(noPlaylistsView)
        noPlaylistsView.delegate = self
    }
    
    private func updateUI() {
        if playlists.isEmpty {
            //Show label
            noPlaylistsView.isHidden = false
        }
        else {
            //Show table
        }
    }
}

extension LibraryPlaylistViewController: ActionLabelViewDelegate {
    func actionLabelViewDidTapButton(_ actionView: ActionLabelView) {
        //Show Creation UI
        let alert = UIAlertController(title: "New Playlists", message: "Enter playlist name", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Playlist..."
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
            guard let field = alert.textFields?.first,
                  let text = field.text,
                  !text.trimmingCharacters(in: .whitespaces).isEmpty else {
                      return
                  }
            APICaller.shared.createPlaylists(with: text) { success in
                if success {
                    //Refresh list of playlists
                }
                else {
                    print("Failed to create playlist")
                }
            }
        }))
    }
}
