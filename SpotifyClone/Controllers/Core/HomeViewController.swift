//
//  ViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 3/29/22.
//

import UIKit

//MARK: - Setup

//Defines what each element of the sections array will be
enum BrowseSectionType {
    case newReleases(viewModels: [NewReleasesCellViewModel])
    case featuredPlaylists(viewModels: [FeaturedPlaylistCellViewModel])
    case recommendedTracks(viewModels: [RecommendedTrackCellViewModel])
    
    //This "title" variable will now be associated with each element("section) in the sections array
    var title: String {
        switch self {
        case .newReleases:
            return "New Released Albums"
        case .featuredPlaylists:
            return "Featured Playlists"
        case .recommendedTracks:
            return "Recommended"
        }
    }
}

class HomeViewController: UIViewController {
    
    private var newAlbums: [Album] = []
    private var playlists: [Playlist] = []
    private var tracks: [AudioTrack] = []
    
    private var collectionView: UICollectionView = UICollectionView(
        frame: .zero,
        //setting the collection view layout as a compositional layout
        //Gets the sectionIndex from the collection view data methods
        collectionViewLayout: UICollectionViewCompositionalLayout { sectionIndex, _ -> NSCollectionLayoutSection in
        return HomeViewController.createSectionLayout(section: sectionIndex)
        }
    )
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.tintColor = .label
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    //Stores the different cell view models of each browsing section type (defined in the enum above)
    //Will only have 3 elements
    private var sections = [BrowseSectionType]()

//MARK: - View Load Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Browse"
        view.backgroundColor = .systemBackground
        
        //Adds the action didTapSettings to the rightBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .done, target: self, action: #selector(didTapSettings))
        
        //Need to add the collection view as a sub view first!
        configureCollectionView()
        view.addSubview(spinner)
        //API calls
        fetchData()
        
        //Configure for Long tap to add a selected track to a saved playlist
        addLongTapGesture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    private func addLongTapGesture() {
        //creates the gesture
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        collectionView.isUserInteractionEnabled = true
        collectionView.addGestureRecognizer(gesture)
    }
    
    @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {return}
        //CGFloat of the position
        let touchPoint = gesture.location(in: collectionView)
        //returns the indexPath of the collectionView where the user performed the gesture
        //makes sure that the gesture is only valid in the recommended tracks section (indexPath.section is 2)
        guard let indexPath = collectionView.indexPathForItem(at: touchPoint), indexPath.section == 2 else {return}
        //pulls out the track that was selected and stores it in "model"
        let model = tracks[indexPath.row]
        //creates the action sheet that will be presented to the user when they long tap a track
        let actionSheet = UIAlertController(title: model.name, message: "Would you like to add this track to a playlist?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        //when the user taps the add button, then the code block in the handler kicks off
        actionSheet.addAction(UIAlertAction(title: "Add to Playlist", style: .default, handler: {[weak self] _ in
            //Need this on the main thread because it's an action in a closure
            DispatchQueue.main.async {
                let vc = LibraryPlaylistViewController()
                //there is a defined sectionHandler in the LibraryPlaylistViewController
                //the code in the sectionHandler won't execute until the section Handler in the LibraryPlaylistViewController passes back "playlist"
                vc.selectionHandler = { playlist in
                    APICaller.shared.addTrackToPlaylists(track: model, playlist: playlist) { success in
                        print("Added to playlist success: \(success)")
                    }
                }
                vc.title = "Select Playlist"
                //presents a modal view of the LibraryPlaylistViewController where the user will select a playlist
                self?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            }
        }))
        present(actionSheet, animated: true)
    }
    
    private func configureCollectionView() {
        view.addSubview(collectionView)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        //Registering the different custome cell types
        collectionView.register(NewReleaseCollectionViewCell.self, forCellWithReuseIdentifier: NewReleaseCollectionViewCell.identifier)
        collectionView.register(FeaturedPlaylistCollectionViewCell.self, forCellWithReuseIdentifier: FeaturedPlaylistCollectionViewCell.identifier)
        collectionView.register(RecommendedTrackCollectionViewCell.self, forCellWithReuseIdentifier: RecommendedTrackCollectionViewCell.identifier)
        collectionView.register(TitleHeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader , withReuseIdentifier: TitleHeaderCollectionReusableView.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground
    }
    
//MARK: - Action Methods
    
    private func fetchData() {
        
        //Using DispatchGroup to make sure we perform the API calls concurrently
        let group = DispatchGroup()
        group.enter()
        group.enter()
        group.enter()
        
        var newReleases: NewReleasesResponse?
        var featuredPlaylist: FeaturedPlaylistsResponse?
        var recommendations: RecommendationsResponse?
        //New Releases
        APICaller.shared.getNewReleases { result in
            //"defer" makes sure that group.leave() is called no matter what when the scope exists
            //Like a safety valve
            defer {
                group.leave()
            }
            switch result {
            //Returns the data model from the API call
            case .success(let model):
                newReleases = model
            case .failure(let error): print(error.localizedDescription)
            }
        }
        //Featured Playlists
        APICaller.shared.getFeaturedPlaylists { result in
            defer {
                group.leave()
            }
            switch result {
            case .success(let model):
                featuredPlaylist = model
                
            case .failure(let error): print(error.localizedDescription)
            }
        }
        //Recommended Tracks
        APICaller.shared.getRecommendedGenres{ result in
           
            switch result {
            case .success(let model):
                let genres = model.genres
                var seeds = Set<String>()
                while seeds.count < 5 {
                    //Grabs a random element in genres and adds it into the seeds Set
                    if let random = genres.randomElement() {
                        seeds.insert(random)
                    }
                }
                //Once the app has the seeds Set populated, use it as a parameter to get the recommendations from the API
                APICaller.shared.getRecommendations(genres: seeds) { recommendedResult in
                    defer {
                        group.leave()
                    }
                    switch recommendedResult {
                    case .success(let model):
                        recommendations = model
                    case .failure(let error): print(error.localizedDescription)
                    }
                    
                }
            case .failure(let error): print(error.localizedDescription)
            }
        }
        
        //Once all the API calls are made, push this thread to Main
        //Unwrap all the properties of the Jsons
        group.notify(queue: .main) {
            guard let newAlbums = newReleases?.albums.items,
                  let playlists = featuredPlaylist?.playlists.items,
                  let tracks = recommendations?.tracks
            else {return}
            //Adds all these models into the sections array
            self.configureModels(newAlbums: newAlbums, playlists: playlists, tracks: tracks)
        }
    }
    
    private func configureModels(newAlbums: [Album], playlists: [Playlist], tracks: [AudioTrack] ) {
        //Configure Models
        
        self.newAlbums = newAlbums
        self.playlists = playlists
        self.tracks = tracks
        
        //Grabbing the properties from each Album and putting it in the NewReleasesCellViewModel
        //In other words, converting the Album object that got passed in into a NewReleaseCellViewModel
        sections.append(.newReleases(viewModels: newAlbums.compactMap({
            return NewReleasesCellViewModel(
                name: $0.name,
                artworkURL: URL(string: $0.images.first?.url ?? ""),
                numberOfTracks: $0.total_tracks,
                artistName: $0.artists.first?.name ?? "-")})))
        
        sections.append(.featuredPlaylists(viewModels: playlists.compactMap({
            return FeaturedPlaylistCellViewModel(
                name: $0.name,
                artworkURL: URL(string: $0.images.first?.url ?? ""),
                creator: $0.owner.display_name )})))
        
        sections.append(.recommendedTracks(viewModels: tracks.compactMap({
            return RecommendedTrackCellViewModel(
                name: $0.name,
                artistName: $0.artists.first?.name ?? "-",
                artworkURL: URL(string: $0.album?.images.first?.url ?? ""))})))
        
        collectionView.reloadData()
    }
    
    @objc func didTapSettings() {
        let vc = SettingsViewController()
        vc.title = "Settings"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }


}

//MARK: - CollectionView Methods

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Seeing how many viewModels are in each section type and returning those numbers
        let type = sections[section]
        switch type {
        case .newReleases(viewModels: let viewModels):
            return viewModels.count
        case .featuredPlaylists(viewModels: let viewModels):
            return viewModels.count
        case .recommendedTracks(viewModels: let viewModels):
            return viewModels.count

        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        //Returns number of elements in the section array (should be 3)yeah
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let type = sections[indexPath.section]
        switch type {
        case .newReleases(viewModels: let viewModels):
            //Implement guard because we are trying to cast it as a particular CollectionViewCell
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NewReleaseCollectionViewCell.identifier, for: indexPath) as? NewReleaseCollectionViewCell
            //Probably won't ever utilize the else statement but just in case
            else { return UICollectionViewCell()}
            let viewModel = viewModels[indexPath.row]
            cell.configure(with: viewModel)
            return cell
            
        case .featuredPlaylists(viewModels: let viewModels):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FeaturedPlaylistCollectionViewCell.identifier, for: indexPath) as? FeaturedPlaylistCollectionViewCell
            else { return UICollectionViewCell()}
            let viewModel = viewModels[indexPath.row]
            cell.configure(with: viewModel)
            return cell
            
        case .recommendedTracks(viewModels: let viewModels):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RecommendedTrackCollectionViewCell.identifier, for: indexPath) as? RecommendedTrackCollectionViewCell
            else { return UICollectionViewCell()}
            let viewModel = viewModels[indexPath.row]
            cell.configure(with: viewModel)
            return cell
        }
    }
    
    //When the user taps on an item (depending on the section) they will be directed to the section's page
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let section = sections[indexPath.section]
        switch section {
        case .featuredPlaylists:
            let playlist = playlists[indexPath.row]
            let vc = PlaylistViewController(playlist: playlist)
            vc.title = playlist.name
            vc.navigationItem.largeTitleDisplayMode = .never
            navigationController?.pushViewController(vc, animated: true)
            
        case .newReleases:
            let album = newAlbums[indexPath.row]
            let vc = AlbumViewController(album: album)
            vc.title = album.name
            vc.navigationItem.largeTitleDisplayMode = .never
            navigationController?.pushViewController(vc, animated: true)
            
        case .recommendedTracks:
            //When a user clicks on a specific track, the player modal will be presented
            let track = tracks[indexPath.row]
            PlaybackPresenter.shared.startPlayback(from: self, track: track)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TitleHeaderCollectionReusableView.identifier, for: indexPath) as? TitleHeaderCollectionReusableView, kind == UICollectionView.elementKindSectionHeader //This "kind" part is to make sure we're passing in a header instead of a footer
        else {return UICollectionViewCell()}
        let section = indexPath.section
        let title = sections[section].title
        header.configure(with: title)
        return header
    }
    
    static func createSectionLayout(section: Int) -> NSCollectionLayoutSection {
        let supplementaryItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)),
                                                                            elementKind: UICollectionView.elementKindSectionHeader,
                                                                            alignment: .top)
        let supplementaryViews = [supplementaryItem]
        switch section {
        
        //New Released Albums
        case 0:
            //Item
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
            
            //Vertical group in a horizontal group
            let verticalGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(390)),
                subitem: item,
                count: 3)
            
            let horizontalGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .absolute(390)),
                subitem: verticalGroup,
                count: 1)
            
            //Section
            let section = NSCollectionLayoutSection(group: horizontalGroup)
            section.orthogonalScrollingBehavior = .groupPaging
            section.boundarySupplementaryItems = supplementaryViews
            return section
        
        //Featured Playlists
        case 1:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(200), heightDimension: .absolute(200)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
            
            let verticalGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(200), heightDimension: .absolute(400)),
                subitem: item,
                count: 2)
            
            let horizontalGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(200), heightDimension: .absolute(400)),
                subitem: verticalGroup,
                count: 1)
            
            let section = NSCollectionLayoutSection(group: horizontalGroup)
            section.orthogonalScrollingBehavior = .continuous
            section.boundarySupplementaryItems = supplementaryViews
            return section
        
        //Recommended Tracks
        case 2:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
            
            let verticalGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80)),
                subitem: item,
                count: 1)
            
            let section = NSCollectionLayoutSection(group: verticalGroup)
            section.boundarySupplementaryItems = supplementaryViews
            return section
        
        default:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
            
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(390)),
                subitem: item,
                count: 1)
            
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = supplementaryViews
            return section
        }
    }
}
