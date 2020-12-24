//
//  AddNameViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 24/12/20.
//

import UIKit
import RealmSwift

class AddNameViewController: UIViewController {
    
    static let _partition = "contacts"

    @IBOutlet weak var firstName: UITextField! {
        didSet {
            firstName.becomeFirstResponder()
        }
    }
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.title = "Add new contact"
        print(Realm.Configuration.defaultConfiguration.fileURL!)
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
            do {
                let realm = try Realm()
                try realm.write {
                    let contact = Contact(partition: AddNameViewController._partition)
                    contact.firstName = _firstName
                    contact.lastName = _lastName
                    realm.add(contact)
                    self.dismiss(animated: true, completion: nil)
                }
            } catch (let error) {
                debugPrint(error.localizedDescription)
                errorLabel.text = "There is an unexpected error trying to save to Realm"
            }
        }
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
