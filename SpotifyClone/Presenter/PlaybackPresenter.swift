//
//  PlaybackPresenter.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/19/22.
//

import Foundation
import UIKit
import AVFoundation

//MARK: - Setup

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
    private var index: Int = 0
    private var numberOfTracks: Int = 0
    private var avItems: [AVPlayerItem]?
    
    //Storing a reference (basically just keeping track) of what track is currently playing
    //currentTrack is what drives the dataSource that the PlayerViewController configures its artwork and titles on
    var currentTrack: AudioTrack? {
        if let track = track {
            return track
        }
        else if !tracks.isEmpty {
            return tracks[index]
        }
        
        return nil
    }
    var playerVC: PlayerViewController?
    
    var player: AVPlayer?
    var playerQueue: AVQueuePlayer?
 
//MARK: - Present Player Methods
    
    //These functions will present the modal that will hold the song player
    
    func startPlayback(from viewController: UIViewController, track: AudioTrack) {
        //Making sure there is a preview to play
        guard let url = URL(string: track.preview_url ?? "") else {return}
            
        player = AVPlayer(url: url)
        player?.volume = 0.1
        
        //since there should only be one audio track that is sent back in the method, store it in self.track
        //make the tracks collection (array) empty. * Empty array -> = [], and not -> = nil *
        self.track = track
        self.tracks = []
        let vc = PlayerViewController()
        vc.title = track.name
        //setting the vc's datasource as this class (PlaybackPresenter)
        vc.dataSource = self
        vc.delegate = self
        //The viewController that calls this function will present a modal of the player
        //Using a trailing closure to implement the completion handler which will play the preview track in the player
        print("Presenting Player")
        viewController.present(UINavigationController(rootViewController: vc), animated: true){[weak self] in
            self?.player?.play()
        }
        self.playerVC = vc
    }
    
    //Will handle Playlists which are just a collection of tracks
    func startPlayback(from viewController: UIViewController, tracks: [AudioTrack]) {
        //since a collection of tracks are sent back, store them in the self.tracks array
        //make self.track nil
        self.tracks = tracks.compactMap({$0})
        self.track = nil
        
        let items: [AVPlayerItem] = tracks.compactMap({
            guard let url = URL(string: $0.preview_url ?? "") else {return nil}
            return AVPlayerItem(url: url)
        })
        self.playerQueue = AVQueuePlayer(items: items)
        self.playerQueue?.volume = 0.1
        self.playerQueue?.play()
        self.avItems = items
        let vc = PlayerViewController()
        vc.dataSource = self
        vc.delegate = self
        viewController.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        self.playerVC = vc
    }
    
    //Will handle Albums which are just a collection of tracks
    func startPlayback(from viewController: UIViewController, track: AudioTrack? ,tracks: [AudioTrack], album: Album) {
        //since a collection of tracks are sent back, store them in the self.tracks array
        //takes out the nil tracks
        self.tracks = tracks.compactMap({$0})
        self.track = track ?? nil
        self.album = album
        
        let items: [AVPlayerItem] = tracks.compactMap({
            guard let url = URL(string: $0.preview_url ?? "") else {return nil}
            return AVPlayerItem(url: url)
        })
        self.numberOfTracks = items.count
        //self.index = 0
        self.avItems = items
        self.playerQueue = AVQueuePlayer(items: items)
        self.playerQueue?.volume = 0.1
        self.playerQueue?.play()
        
        let vc = PlayerViewController()
        vc.dataSource = self
        vc.delegate = self
        viewController.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        self.playerVC = vc
    }
    
    
    
}

//MARK: - Player Control Methods

extension PlaybackPresenter: PlayerViewControllerDelegate {
    func didTapPlayPause() {
        print("PlaybackPresenter Play/Pause")
        
        if let player = self.player {
            print("player pause/play")
            if player.timeControlStatus == .playing {
                player.pause()
            } else if player.timeControlStatus == .paused {
                player.play()
            }
        }
        else if let playerQ = playerQueue {
            print("playerQ pause/play")
            if playerQ.timeControlStatus == .playing {
                playerQ.pause()
            } else if playerQ.timeControlStatus == .paused {
                playerQ.play()
            }
        }
        
    }
    
    func didTapForward() {
        if tracks.isEmpty {
            //Not a playlist or album
            player?.pause()
        }
        else if let player = playerQueue, index + 1 < numberOfTracks {
            player.advanceToNextItem()
            index += 1
            print(index)
            playerVC?.refreshUI()
        }
    }
    
    func didTapBackward() {
        if tracks.isEmpty {
            //Not a playlist or album
            player?.pause()
            player?.play()
        }
        else if let items = avItems {
            playerQueue?.pause()
//            playerQueue?.removeAllItems()
//            playerQueue?.replaceCurrentItem(with: nil)
            playerQueue = AVQueuePlayer(items: Array(items.dropFirst(index)))
            playerQueue?.play()
            playerQueue?.volume = 0.2
        }
    }
    
    func didSlideSlider(_ value: Float) {
        if let player = player {
            player.volume = value
        }
        else if let player = playerQueue {
            player.volume = value
        }
    }
}

//MARK: - Player Control Data

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
