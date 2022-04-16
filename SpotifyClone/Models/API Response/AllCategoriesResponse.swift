//
//  AllCategoriesResponse.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/15/22.
//

import Foundation

struct AllCategoriesResponse: Codable {
    let categories: Categories
}

struct Categories: Codable {
    let items: [Category]
}

struct Category: Codable {
    let icons: [APIImage]
    let id: String
    let name: String
}
