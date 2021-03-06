//
//  FeaturedPlaylistsResponse.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/8/22.
//

import Foundation

struct FeaturedPlaylistsResponse: Codable {
    let playlists: PlaylistResponse
}

struct CategoriesPlaylistsResponse: Codable {
    let playlists: PlaylistResponse
}

struct PlaylistResponse: Codable {
    let items: [Playlist]
}



struct User: Codable {
    let display_name: String
    let external_urls: [String: String]
    let id: String
}
