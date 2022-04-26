//
//  LibraryAlbumsResponse.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/25/22.
//

import Foundation

struct LibraryAlbumsResponse: Codable {
    let items: [LibraryAlbum]
}

struct LibraryAlbum: Codable {
    let album: Album
}


