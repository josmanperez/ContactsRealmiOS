//
//  LoginViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 4/1/21.
//

import UIKit
import RealmSwift
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInDelegate {
    
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
    @IBOutlet weak var googleSignInBtn: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.delegate = self
        
        if GIDSignIn.sharedInstance()?.currentUser != nil {
            GIDSignIn.sharedInstance()?.signOut()
        } 
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        GIDSignIn.sharedInstance()?.signOut()
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signet out")
            } else {
                print("\(error.localizedDescription)")
            }
            return
        }
        print(">> \(user.profile.email ?? "no email")")
        guard let serverAuthCode = user.serverAuthCode else { return }
        let credentials = Credentials.googleId(token: serverAuthCode)
        app.login(credentials: credentials) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print("Failed to log in to MongoDB Realm: \(error)")
                case .success(let user):
                    print("Successfully logged in to MongoDB Realm using Google Oauth")
                    self.openRealmFor(user: user)
                }
            }
        }
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
        guard let email = email.text, let password = password.text else { return }
        setLoading(true)
        app.emailPasswordAuth.registerUser(email: email, password: password) { [weak self](error) in
            DispatchQueue.main.async {
                self?.setLoading(false)
                guard error == nil else {
                    print("Signup failed \(error!)")
                    self?.errorMessage.text = "Signup failed: \(error?.localizedDescription ?? "")"
                    self?.errorMessage.isHidden = false
                    return
                }
                self?.errorMessage.text = "Signup successful!"
                self?.signIn()
            }
        }
        
    }
    
    
    @IBAction func signIn() {
        guard let email = email.text, let password = password.text else { return }
        setLoading(true)
        app.login(credentials: Credentials.emailPassword(email: email, password: password)) {
            result in
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case .success(let user):
                    self.openRealmFor(user: user)
                case .failure(let error):
                    self.errorMessage.text = "Login failed: \(error.localizedDescription)"
                    self.errorMessage.isHidden = false
                    return
                }
            }
        }
        
    }
    
    private func openRealmFor(user: User) {
        self.setLoading(true)
        var configuraiton = user.configuration(partitionValue: "user=\(user.id)")
        configuraiton.objectTypes = [Usuario.self, Contact.self]
        Realm.asyncOpen(configuration: configuraiton) {
            [weak self](result) in
            self?.setLoading(false)
            switch result {
            case .failure(let error):
                self?.errorMessage.text = "Failed to open Realm \(error.localizedDescription)"
            case .success(let userRealm):
                self?.performSegue(withIdentifier: "showContactList", sender: userRealm)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContactList" {
            if let vc = segue.destination as? UINavigationController, let targetController = vc.topViewController as? ContactListViewController, let realm = sender as? Realm {
                vc.modalPresentationStyle = .fullScreen
                targetController.realm = realm
            }
        }
    }
    
    
}
