//
//  ContactViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 24/12/20.
//

import UIKit
import RealmSwift

class ContactViewController: UIViewController {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    
    var contact: Contact?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureFields()
    }
    
    func configureFields() {
        guard let _contact = contact else { return }
        firstName.text = _contact.firstName
        lastName.text = _contact.lastName
    }

}
