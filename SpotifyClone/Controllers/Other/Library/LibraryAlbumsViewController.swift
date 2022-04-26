//
//  LibraryAlbumsViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/23/22.
//

import UIKit

class LibraryAlbumsViewController: UIViewController {
    
    var albums: [Album] = []
    
    private let noAlbumsView = ActionLabelView()
    
    //observer for notification of whenever user adds//saves a new album
    private var observer: NSObjectProtocol?
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(SearchResultSubtitleTableViewCell.self, forCellReuseIdentifier: SearchResultSubtitleTableViewCell.identifier)
        tableView.isHidden = true
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        setUpNoAlbumsView()
        fetchCurrentAlbums()
        
        //observing for notifications for when the user adds a new saved album. Will trigger a API call to fetch
        observer = NotificationCenter.default.addObserver(forName: .albumSavedNotification, object: nil, queue: .main, using: {[weak self] _ in
            self?.fetchCurrentAlbums()
        })
        
    }
    
    @objc func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noAlbumsView.frame = CGRect(x: (view.width - 150)/2, y: (view.height - 150)/2, width: 150, height: 150)
        //noAlbumsView.center = view.center
        tableView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
       
    }
    
    private func fetchCurrentAlbums() {
        //whenever we add a new album we want to refresh this view so we are going to clear the albums whenever we make a new API call
        albums.removeAll()
        APICaller.shared.getCurrentUserAlbums { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    //the LibraryAlbumsResponse's items object had another pesky property so I couldn't just pull out an [Album] easily
                    //I needed to pull out the individual album out of each object in items (use compactMap)
                    self?.albums = model.items.compactMap({$0.album})
                    self?.updateUI()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private func setUpNoAlbumsView() {
        noAlbumsView.configure(with: ActionLabelViewViewModel(text: "You don't have any saved albums yet", actionTitle: "Browse"))
        view.addSubview(noAlbumsView)
        noAlbumsView.delegate = self
    }
    
    private func updateUI() {
        if albums.isEmpty {
            //Show label
            noAlbumsView.isHidden = false
        }
        else {
            //Show table
            tableView.reloadData()
            tableView.isHidden = false
            noAlbumsView.isHidden = true
        }
    }
    
}

extension LibraryAlbumsViewController: ActionLabelViewDelegate {
    func actionLabelViewDidTapButton(_ actionView: ActionLabelView) {
        //switching the app to the "Browse"/"Home" tab/page
        tabBarController?.selectedIndex = 0
    }
}

extension LibraryAlbumsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultSubtitleTableViewCell.identifier, for: indexPath) as? SearchResultSubtitleTableViewCell else {
            return UITableViewCell()
        }
        let album = albums[indexPath.row]
        cell.configure(with: SearchResultSubtitleTableViewCellViewModel(
                                title: album.name,
                                subtitle: album.artists.first?.name ?? "-",
                                imageURL: URL(string: album.images.first?.url ?? "")))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        HapticsManager.shared.vibrateForSelection()
        
        let album = albums[indexPath.row]
        let vc = AlbumViewController(album: album)
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}

    

