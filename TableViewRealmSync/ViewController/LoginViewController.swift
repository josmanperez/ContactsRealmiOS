//
//  LoginViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 4/1/21.
//

import UIKit
import RealmSwift
import Realm.RLMUser
import GoogleSignIn
import FirebaseUI

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
    @IBOutlet weak var otherProviders: UIButton!
    
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
        otherProviders.isEnabled = !loading
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
    
    @IBAction func openProviders(_ sender: Any) {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.providers = [FUIOAuth.githubAuthProvider()]
        authUI?.delegate = self
        guard let viewController = authUI?.authViewController() else { return }
        present(viewController, animated: true, completion: nil)
    }
    
    /** Function to authenticate a user using the `Credentials` for `jwt`
     */
    private func userAuthenticatedWithJWT(with firebaseAuth: AuthDataResult?) {
        Auth.auth().currentUser?.getIDToken(completion: { (token, error) in
            guard let token = token else {
                // TO-DO: Handle error
                return }
            print(token)
            app.login(credentials: Credentials.jwt(token: token)) {
                result in
                DispatchQueue.main.async {
                    self.setLoading(false)
                    switch result {
                    case .success(let user):
                        if let jwtResult = firebaseAuth {
                            self.saveCustomUserData(user: user, jwtResult: jwtResult)
                        }
                        self.openRealmFor(user: user)
                    case .failure(let error):
                        self.errorMessage.text = "Login failed: \(error.localizedDescription)"
                        self.errorMessage.isHidden = false
                        return
                    }
                }
            }
        })
    }
    
    /** Function to save custom user data when using `JWT` token for `Credentials`
     *
     */
    private func saveCustomUserData(user: RLMUser, jwtResult: AuthDataResult) {
        // Write using MongoDB
        let client = user.mongoClient("mongodb-atlas")
        let database = client.database(named: "testSync")
        let collection = database.collection(withName: "CustomUserData")
        
        collection.updateOneDocument(
            filter: ["userId" : AnyBSON(user.id)],
            update: [
            "userId": AnyBSON(user.id),
            "uuid": AnyBSON(jwtResult.user.uid),
            "picture": AnyBSON("\(jwtResult.user.photoURL?.absoluteString ?? "")")
        ], upsert: true) { result in
            switch result {
            case .failure(let error):
                print("Failed to insert document \(error.localizedDescription)")
            case .success(let updateResult):
                print("Matched: \(updateResult.matchedCount), updated: \(updateResult.modifiedCount)")
            }
        }
                
    }
    
    private func openRealmFor(user: RLMUser) {
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

extension LoginViewController: FUIAuthDelegate {
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error as NSError?,
           error.code == FUIAuthErrorCode.mergeConflict.rawValue {
            // Merge conflict error, discard the anonymous user and login as the existing
            // non-anonymous user.
            guard let credential = error.userInfo[FUIAuthCredentialKey] as? AuthCredential else {
                print("Received merge conflict error without auth credential!")
                return
            }
            
            Auth.auth().signIn(with: credential) { (dataResult, error) in
                if let error = error as NSError? {
                    print("Failed to re-login: \(error)")
                    return
                }
                self.userAuthenticatedWithJWT(with: authDataResult)
            }
        } else if let error = error {
            // Some non-merge conflict error happened.
            print("Failed to log in: \(error)")
            return
        }
        userAuthenticatedWithJWT(with: authDataResult)
    }
}
