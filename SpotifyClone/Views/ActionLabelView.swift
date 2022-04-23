//
//  ActionLabelView.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 4/23/22.
//

import UIKit

struct ActionLabelViewViewModel {
    let text: String
    let actionTitle: String
}

class ActionLabelView: UIView {
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let button: UIButton = {
        let button = UIButton()
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func configure(with viewModel: ActionLabelViewViewModel){
        
    }
    

}
