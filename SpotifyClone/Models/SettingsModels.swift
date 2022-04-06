//
//  SettingsModels.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/6/22.
//

import Foundation

struct Section {
    let title: String
    let options: [Option]
}

struct Option {
    let title: String
    let handler: () -> Void
}
