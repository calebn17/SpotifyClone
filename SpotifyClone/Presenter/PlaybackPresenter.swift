//
//  PlaybackPresenter.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/19/22.
//

import Foundation
import UIKit

protocol PlayerDataSource: AnyObject {
    var songName: String? {get}
    var subtitle: String? {get}
    var imageURL: URL? {get}
}

final class PlaybackPresenter {
    
    static let shared = PlaybackPresenter()
    
    private var track: AudioTrack?
    private var tracks = [AudioTrack]()
    
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
        self.track = track
        self.tracks = []
        let vc = PlayerViewController()
        vc.title = track.name
        vc.dataSource = self
        //The viewController that calls this function will present a modal of the player
        viewController.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    //Will handle Albums and Playlists which are just a collection of tracks
    func startPlayback(from viewController: UIViewController, tracks: [AudioTrack]) {
        self.tracks = tracks
        self.track = nil
        let vc = PlayerViewController()
        viewController.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    
}

extension PlaybackPresenter: PlayerDataSource {
    var songName: String? {
        return currentTrack?.name
    }
    
    var subtitle: String? {
        return currentTrack?.artists.first?.name
    }
    
    var imageURL: URL? {
        return URL(string: currentTrack?.album?.images.first?.url ?? "")
    }
    
    
}
