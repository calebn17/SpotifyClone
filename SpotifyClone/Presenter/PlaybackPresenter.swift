//
//  PlaybackPresenter.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/19/22.
//

import Foundation
import UIKit

protocol PlayerDataSource: AnyObject {
    //Need {get} because the datasource is returning variables
    var songName: String? {get}
    var subtitle: String? {get}
    var imageURL: URL? {get}
    var albumImageURL: URL? {get}
}

final class PlaybackPresenter {
    
    //This class will be the datasource for the PlayerViewController because all the data from other Controllers come through here first
    
    static let shared = PlaybackPresenter()
    
    //Variables used to help store the tracks that are being sent to this class from other controllers
    private var track: AudioTrack?
    private var tracks = [AudioTrack]()
    private var album: Album?
    
    //Storing a reference (basically just keeping track) of what track is currently playing
    var currentTrack: AudioTrack? {
        if let track = track, tracks.isEmpty{
            return track
        }
        else if !tracks.isEmpty {
            return tracks.first
        }
        
        return nil
    }
    
    //These functions will present the modal that will hold the song player
    
    func startPlayback(from viewController: UIViewController, track: AudioTrack) {
        //since there should only be one audio track that is sent back in the method, store it in self.track
        //make the tracks collection (array) empty. * Empty array -> = [], and not -> = nil *
        self.track = track
        self.tracks = []
        let vc = PlayerViewController()
        vc.title = track.name
        //setting the vc's datasource as this class (PlaybackPresenter)
        vc.dataSource = self
        //The viewController that calls this function will present a modal of the player
        viewController.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    //Will handle Playlists which are just a collection of tracks
    func startPlayback(from viewController: UIViewController, tracks: [AudioTrack]) {
        //since a collection of tracks are sent back, store them in the self.tracks array
        //make self.track nil
        self.tracks = tracks
        self.track = nil
        let vc = PlayerViewController()
        vc.dataSource = self
        viewController.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    //Will handle Albums which are just a collection of tracks
    func startPlayback(from viewController: UIViewController, track: AudioTrack? ,tracks: [AudioTrack]?, album: Album) {
        //since a collection of tracks are sent back, store them in the self.tracks array
        //make self.track nil
        self.tracks = tracks ?? []
        self.track = track ?? nil
        self.album = album
        let vc = PlayerViewController()
        vc.dataSource = self
        viewController.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    
    
}

//The Data that this class (as the DataSource) is sending back
extension PlaybackPresenter: PlayerDataSource {
    //Grabbing the data based on the currentTrack that we stored from the startPlayback methods
    
    var songName: String? {
        return currentTrack?.name
    }
    
    var subtitle: String? {
        return currentTrack?.artists.first?.name
    }
    
    var imageURL: URL? {
        return URL(string: currentTrack?.album?.images.first?.url ?? "")
    }
    
    var albumImageURL: URL? {
        return URL(string: self.album?.images.first?.url ?? "")
    }
    
    
    
}
