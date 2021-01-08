//
//  LoginViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 4/1/21.
//

import UIKit
import RealmSwift

class LoginViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.isHidden = true
        }
    }
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var errorMessage: UILabel! {
        didSet {
            errorMessage.textColor = .systemRed
            errorMessage.isHidden = true
        }
    }
    @IBOutlet weak var signUpBtn: UIButton!
    @IBOutlet weak var signInBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.stopAnimating()
            errorMessage.text = ""
        } else {
            activityIndicator.startAnimating()
        }
        activityIndicator.isHidden = !loading
        signUpBtn.isEnabled = !loading
        signInBtn.isEnabled = !loading
        password.isEnabled = !loading
        email.isEnabled = !loading
    }

    @IBAction func signUp(_ sender: Any) {
        
        
    }
    
    
    @IBAction func signIn(_ sender: Any) {
        guard let email = email.text, let password = password.text else { return }
        setLoading(true)
        app.login(credentials: Credentials.emailPassword(email: email, password: password)) {
            result in
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case .success(let user):
                    var configuraiton = user.configuration(partitionValue: "user=\(user.id)")
                    configuraiton.objectTypes = [Contact.self]
                case .failure(let error):
                    self.errorMessage.text = "Login failed: \(error.localizedDescription)"
                    self.errorMessage.isHidden = false
                    return
                }
            }
        }

    }
    

}
