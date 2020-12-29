//
//  AddNameViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 24/12/20.
//

import UIKit
import RealmSwift

class AddNameViewController: UIViewController {

    @IBOutlet weak var firstName: UITextField! {
        didSet {
            firstName.becomeFirstResponder()
        }
    }
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    fileprivate func saveContact(firstName: String, lastName: String, completionHandler: @escaping (Bool) -> Void) {
        let user = app.currentUser!
        Realm.asyncOpen(configuration: user.configuration(partitionValue: Contact._partition)) {
            (resutl) in
            switch resutl {
            case .failure(let error):
                debugPrint("Failed to open realm: \(error.localizedDescription)")
                completionHandler(false)
            case .success(let realm):
                do {
                    try realm.write {
                        let contact = Contact(partition: Contact._partition)
                        contact.firstName = firstName
                        contact.lastName = lastName
                        realm.add(contact)
                        completionHandler(true)
                    }
                } catch (let error) {
                    debugPrint("Failed to open realm: \(error.localizedDescription)")
                    completionHandler(false)
                }
            }
        }
    }

    @IBAction func save(_ sender: Any) {
        if !firstName.hasText || !lastName.hasText {
            errorLabel.text = "Both first name & last name are mandatory"
        } else {
            guard let _firstName = firstName.text, let _lastName = lastName.text else {
                errorLabel.text = "An unexpected error has occurred"
                return
            }
            errorLabel.text?.removeAll()
            saveContact(firstName: _firstName, lastName: _lastName) {
                success in
                if success {
                    self.dismiss(animated: true)
                } else {
                    self.errorLabel.text = "There is an unexpected error trying to save to Realm"
                }
            }
        }
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
