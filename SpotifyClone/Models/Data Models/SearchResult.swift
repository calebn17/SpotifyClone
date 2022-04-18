//
//  SearchResult.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/18/22.
//

import Foundation

enum SearchResult {
    case artist(model: Artist)
    case album(model: Album)
    case track(model: AudioTrack)
    case playlist(model: Playlist)
}
