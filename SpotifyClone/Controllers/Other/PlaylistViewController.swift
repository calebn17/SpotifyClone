//
//  PlaylistViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 3/30/22.
//

import UIKit

class PlaylistViewController: UIViewController{

//MARK: - Setup
    
    private let playlist: Playlist
    
    public var isOwner = false
    
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
    
    init(playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }
    
    //Going to be storing the cell view models here
    private var viewModels = [RecommendedTrackCellViewModel]()
    //Storing the indiviual tracks in the playlist here
    private var tracks = [AudioTrack]()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        title = playlist.name
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        //Reusing the RecommendedTrackCollectionViewCell here because it fits what we would want on this screen
        collectionView.register(RecommendedTrackCollectionViewCell.self, forCellWithReuseIdentifier: RecommendedTrackCollectionViewCell.identifier)
        //Registering the collection header
        collectionView.register(PlaylistHeaderCollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PlaylistHeaderCollectionReusableView.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        
        fetchData()
        
        //Adding a share button in the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didTapShare))
        
        //To remove tracks from saved Playlist
        addLongTapGesture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    

//MARK: - Action Methods
    
    private func addLongTapGesture() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        collectionView.addGestureRecognizer(gesture)
    }
    
    //To Remove tracks from custom Playlist
    @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let touchPoint = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: touchPoint) else {return}
        let trackToDelete = tracks[indexPath.row]
        
        let actionSheet = UIAlertController(title: trackToDelete.name, message: "Would you like to remove this from the playlist?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] _ in
            //need a strongly held self so unwrapping it here
            guard let strongSelf = self else {return}
            APICaller.shared.removeTrackFromPlaylists(track: trackToDelete, playlist: strongSelf.playlist) { success in
                if success {
                    DispatchQueue.main.async {
                        strongSelf.tracks.remove(at: indexPath.row)
                        strongSelf.viewModels.remove(at: indexPath.row)
                        strongSelf.collectionView.reloadData()
                    }
                    
                }
                else {
                    print("Failed to remove")
                }
            }
        }))
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    @objc private func didTapShare() {
        //added key "spotify" because external_urls is a dictionary and we want to just grap the value (the actual url)
        guard let url = URL(string: playlist.external_urls["spotify"] ?? "") else {return}
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }
    
    
    private func fetchData() {
        APICaller.shared.getPlaylistDetails(for: playlist) {[weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    //Pulling out the indiviual audio tracks from the model and putting it in the tracks array
                    self?.tracks = model.tracks.items.compactMap({$0.track})
                    //Taking the model(PlaylistDetailsResponse) and mapping it to the viewModels array ([RecommendedTrackCellViewModel]) so we can use it in this controller
                    self?.viewModels = model.tracks.items.compactMap({
                        RecommendedTrackCellViewModel(name: $0.track.name,
                                                      artistName: $0.track.artists.first?.name ?? "-",
                                                      artworkURL: URL(string: $0.track.album?.images.first?.url ?? ""))
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

extension PlaylistViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Each element in the viewModels array is a track that will be displayed
        return viewModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendedTrackCollectionViewCell.identifier, for: indexPath) as? RecommendedTrackCollectionViewCell
        else { return UICollectionViewCell() }
        
        //Using the configure method in RecommendedTrackCollectionViewCell to configure the cell with the data found in each element of the viewModels array
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    //Adds the Header section
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PlaylistHeaderCollectionReusableView.identifier, for: indexPath) as? PlaylistHeaderCollectionReusableView, kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        //Using the Playlist object that was passed into this VC and parsing it into a PlaylistHeaderViewViewModel so we can configure it
        let headerViewModel = PlaylistHeaderViewViewModel(name: playlist.name, ownerName: playlist.owner.display_name, description: playlist.description, artworkURL: URL(string: playlist.images.first?.url ?? ""))
        //Using the configure method in PlaylistHeaderCollectionReusableView to configure the header section using hte data from headerViewModel
        header.configure(with: headerViewModel)
        //Setting the header as the delegate for the PlayAll button
        header.delegate = self
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        //When the user clicks on a certain song in the playlist, the app will present a modal with the player
        let index = indexPath.row
        let track = tracks[index]
        PlaybackPresenter.shared.startPlayback(from: self, track: track)
    }
    
}

//MARK: - PlaylistHeaderCollectionReusableViewDelegate method

extension PlaylistViewController: PlaylistHeaderCollectionReusableViewDelegate {
    func playlistHeaderCollectionReusableViewDidTapPlayAll(_ header: PlaylistHeaderCollectionReusableView) {
        //When the user clicks the circular green play button, a modal will be presented with the player
        PlaybackPresenter.shared.startPlayback(from: self, tracks: tracks)
    }
}
