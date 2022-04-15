//
//  AlbumViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/12/22.
//

import UIKit

class AlbumViewController: UIViewController {
    
    private let album: Album
    
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    
    //MARK: - Action Methods
    private func fetchData() {
        APICaller.shared.getAlbumDetails(for: album) {[weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
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
        
        //Using the Album object that was passed into this VC and mapping it into a PlaylistHeaderViewViewModel so we can configure it
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
    }
    
}

//MARK: - PlaylistHeaderCollectionReusableViewDelegate method

//Reusing the PlaylistHeaderCollectionReusableViewDelegate
extension AlbumViewController: PlaylistHeaderCollectionReusableViewDelegate {
    func playlistHeaderCollectionReusableViewDidTapPlayAll(_ header: PlaylistHeaderCollectionReusableView) {
        //Start playlist play in queue
        print("PlayAll")
    }
}




