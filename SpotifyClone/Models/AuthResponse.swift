//
//  AuthResponse.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/5/22.
//

import Foundation

//json model
struct AuthResponse: Codable {
    
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
    let token_type: String
    
}
