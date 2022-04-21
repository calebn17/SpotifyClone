//
//  SearchResultsViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 3/30/22.
//

import UIKit

//MARK: - Setup

//Created the data model so that we can attach a title to each SearchResult
struct SearchSection {
    let title: String
    let results: [SearchResult]
}

protocol SearchResultsViewControllerDelegate: AnyObject {
    func didTapResult(_ result: SearchResult)
}

class SearchResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: SearchResultsViewControllerDelegate?
    private var sections: [SearchSection] = []
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(SearchResultDefaultTableViewCell.self, forCellReuseIdentifier: SearchResultDefaultTableViewCell.identifier)
        tableView.register(SearchResultSubtitleTableViewCell.self, forCellReuseIdentifier: SearchResultSubtitleTableViewCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.isHidden = true
        return tableView
    }()

//MARK: - View Load Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

//MARK: - Action Methods
    
    func update(with results: [SearchResult]) {
        //will filter results for the particular case (.artists) and will return "true" if it's there and will also throw an array of the elements that match the case
        //ex. will return an array of artists
        let artists = results.filter({
            switch $0 {
            case .artist: return true
            default: return false
            }
        })
        let albums = results.filter({
            switch $0 {
            case .album: return true
            default: return false
            }
        })
        let tracks = results.filter({
            switch $0 {
            case .track: return true
            default: return false
            }
        })
        let playlists = results.filter({
            switch $0 {
            case .playlist: return true
            default: return false
            }
        })
        //taking the different arrays that match the cases and putting them in the sections array as such
        self.sections = [
            SearchSection(title: "Songs", results: tracks),
            SearchSection(title: "Artists", results: artists),
            SearchSection(title: "Playlists", results: playlists),
            SearchSection(title: "Albums", results: albums),
        ]
        tableView.reloadData()
        //if there ARE results then the tableView is NOT hidden
        tableView.isHidden = results.isEmpty
    }
  
//MARK: - TableView Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        //the sections in this case would be if there are songs, artists, playlists, and albums (if there are any)
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //returns the number of elements in the array. so for the song section, it would return the number of tracks that are in that array
        return sections[section].results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //going through each section and the items (ex tracks) in each section
        let result = sections[indexPath.section].results[indexPath.row]
       
        
        switch result {
        case .artist(let artist):
            //Ex. if the result at this position is an artists then it sets the cell text label to be the name of that Artist
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultDefaultTableViewCell.identifier, for: indexPath)
                    as? SearchResultDefaultTableViewCell
            else { return UITableViewCell()}
            let artist = SearchResultDefaultTableViewCellViewModel(title: artist.name, imageURL: URL(string: artist.images?.first?.url ?? ""))
            cell.configure(with: artist)
            return cell
        
        case .album(let album):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultSubtitleTableViewCell.identifier, for: indexPath)
                    as? SearchResultSubtitleTableViewCell
            else { return UITableViewCell()}
            let album = SearchResultSubtitleTableViewCellViewModel(title: album.name, subtitle: album.artists.first?.name ?? "", imageURL: URL(string: album.images.first?.url ?? ""))
            cell.configure(with: album)
            return cell
        
        case .track(let track):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultSubtitleTableViewCell.identifier, for: indexPath)
                    as? SearchResultSubtitleTableViewCell
            else { return UITableViewCell()}
            let track = SearchResultSubtitleTableViewCellViewModel(title: track.name, subtitle: track.name, imageURL: URL(string: track.album?.images.first?.url ?? ""))
            cell.configure(with: track)
            return cell
        
        case .playlist(let playlist):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultSubtitleTableViewCell.identifier, for: indexPath)
                    as? SearchResultSubtitleTableViewCell
            else { return UITableViewCell()}
            let playlist = SearchResultSubtitleTableViewCellViewModel(title: playlist.name, subtitle: playlist.description, imageURL: URL(string: playlist.images.first?.url ?? ""))
            cell.configure(with: playlist)
            return cell
        }
        
       
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //Whichever cell the user taps on, pass that cells info to the delegate (which is the SearchViewController to push a new view controller)
        let result = sections[indexPath.section].results[indexPath.row]
        delegate?.didTapResult(result)
        
    }
}
