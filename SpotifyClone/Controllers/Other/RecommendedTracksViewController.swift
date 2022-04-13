//
//  RecommendedTracksViewController.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/12/22.
//

import UIKit

class RecommendedTracksViewController: UIViewController {
    
    private let track: AudioTrack
    
    init(track: AudioTrack) {
        self.track = track
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = track.name
        view.backgroundColor = .systemBackground

    }

}
