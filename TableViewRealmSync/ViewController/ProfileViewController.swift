//
//  ProfileViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 18/3/21.
//

import UIKit
import RealmSwift
import Kingfisher

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profilePic: UIImageView! {
        didSet {
            self.profilePic.layer.masksToBounds = true
            self.profilePic.layer.cornerRadius = self.profilePic.frame.height / 2
            self.profilePic.clipsToBounds = true
        }
    }
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var email: UILabel!
    
    var userData: Usuario?
    
    override func viewDidLoad() {
        
        guard let user = app.currentUser, let userData = userData else {
            return
        }
        
        name.text = userData.name
        email.text = userData.email
    
        user.refreshCustomData {
            (result) in
                switch result {
                case .failure(let error):
                    print("Failed to refresh custom data: \(error.localizedDescription)")
                case .success(let customData):
                    guard let profileURL = customData["picture"] as? String else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.loadProfilePic(profileURL: profileURL)
                    }
                }
        }
        
    }
    
    private func loadProfilePic(profileURL: String) {
        let url = URL(string: profileURL)
        
        let processor = DownsamplingImageProcessor(size: profilePic.bounds.size)
                     |> RoundCornerImageProcessor(cornerRadius: 20)
        profilePic.kf.indicatorType = .activity
        profilePic.kf.setImage(
            with: url,
            placeholder: UIImage(named: "profile"),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
    }
    
}
