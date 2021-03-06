//
//  AlbumViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/12/22.
//

import UIKit

class AlbumViewController: UIViewController {
    
    //Album here only has info about the album but not the audio tracks
    private let album: Album
    
    //Storing the individual track of the album here
    private var tracks = [AudioTrack]()
    
    //Going to be storing the cell view models here
    private var viewModels = [AlbumCollectionViewCellViewModel]()
    
    
    //Creates a collection view for the playlist screen. Using a compositional layout
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(sectionProvider: { _, _ -> NSCollectionLayoutSection? in
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 2, bottom: 1, trailing: 2)
        
        let verticalGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60)),
            subitem: item,
            count: 1)
        
        let section = NSCollectionLayoutSection(group: verticalGroup)
        
        //Adding a header for this collectionview/screen
        section.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1)),
                                                        elementKind: UICollectionView.elementKindSectionHeader,
                                                        alignment: .top
                                                       )]
        return section
    }))
    
    //Need init to be able to pass an album in
    init(album: Album) {
        self.album = album
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = album.name
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        //Created the AlbumTrackCollectionViewCell to configure how the track cells in Albums would look
        //AlbumTrackCollectionViewCell is the same as RecommendedTrackCollectionViewCell but without the artwork
        collectionView.register(AlbumTrackCollectionViewCell.self, forCellWithReuseIdentifier: AlbumTrackCollectionViewCell.identifier)
        //Registering the collection header
        collectionView.register(PlaylistHeaderCollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PlaylistHeaderCollectionReusableView.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        
        fetchData()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didTapActions))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    
    //MARK: - Action Methods
    
    @objc func didTapActions() {
        let actionSheet = UIAlertController(title: album.name, message: "Actions", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Save Album", style: .default, handler: {[weak self] _ in
            
            guard let strongSelf = self else {return}
            APICaller.shared.addAlbumToLibrary(album: strongSelf.album) {  success in
                if success {
                    HapticsManager.shared.vibrate(for: .success)
                    NotificationCenter.default.post(name: .albumSavedNotification, object: nil)
                }
                else {
                    HapticsManager.shared.vibrate(for: .error)
                }
            }
        }))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func fetchData() {
        APICaller.shared.getAlbumDetails(for: album) {[weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    //Storing the tracks in the album into the tracks array
                    self?.tracks = model.tracks.items
                    //Taking the model(AlbumDetailsResponse) and mapping it to the AlbumCollectionViewCellViewModel so we can use it in this controller
                    self?.viewModels = model.tracks.items.compactMap({
                        AlbumCollectionViewCellViewModel(name: $0.name,
                                                      artistName: $0.artists.first?.name ?? "-")
                    })
                    self?.collectionView.reloadData()
                case .failure(let error):
                    print("Playlist Response error: \(error)")
                    break
                }
            }
        }
    }
}

//MARK: - Collection View Delegate and Datasource methods

extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Each element in the viewModels array is a track that will be displayed
        return viewModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumTrackCollectionViewCell.identifier, for: indexPath) as? AlbumTrackCollectionViewCell
        else { return UICollectionViewCell() }
        
        //Using the configure method in RecommendedTrackCollectionViewCell to configure the cell with the data found in each element of the viewModels array
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    //Adds the Header section
    //Reusing the PlaylistHeaderCollectionReusableView because it also fits this situation
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PlaylistHeaderCollectionReusableView.identifier, for: indexPath) as? PlaylistHeaderCollectionReusableView, kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        //Using the Album object that was passed into this VC and mapping it into a PlaylistHeaderViewViewModel so we can configure it to display
        let headerViewModel = PlaylistHeaderViewViewModel(
            name: album.name,
            ownerName: album.artists.first?.name,
            description: "Release Date: \(String.formattedDate(string: album.release_date))", //Created date format extensions
            artworkURL: URL(string: album.images.first?.url ?? ""))
        
        //Using the configure method in PlaylistHeaderCollectionReusableView to configure the header section using the data from headerViewModel
        header.configure(with: headerViewModel)
        
        //Setting the header as the delegate for the PlayAll button
        header.delegate = self
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        //Play song
        //Pulls out the individual track that the user clicked on
        let track = tracks[indexPath.row]
        //Passes the track back to the PlaybackPresenter which will push a modal with the player
        PlaybackPresenter.shared.startPlayback(from: self, track: track, tracks: tracks, album: album)
        print("The AlbumViewController is sending this image back to the PlaybackPresenter: \(track.album?.images.first?.url ?? "no image url")")
    }
    
}

//MARK: - PlaylistHeaderCollectionReusableViewDelegate method

//Reusing the PlaylistHeaderCollectionReusableViewDelegate
extension AlbumViewController: PlaylistHeaderCollectionReusableViewDelegate {
    func playlistHeaderCollectionReusableViewDidTapPlayAll(_ header: PlaylistHeaderCollectionReusableView) {
        //When the user clicks the circular green play button, a modal will be presented with the player
        PlaybackPresenter.shared.startPlayback(from: self, track: nil, tracks: tracks, album: self.album)
        print("The AlbumViewController is sending this image back to the PlaybackPresenter: \(album.images.first?.url ?? "no image url")")
    }
}




