//
//  AddNameViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 24/12/20.
//

import UIKit

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

        // Do any additional setup after loading the view.
    }

    @IBAction func save(_ sender: Any) {
        if !firstName.hasText || !lastName.hasText {
            errorLabel.text = "Both first name & last name are mandatory"
        } else {
            errorLabel.text?.removeAll()
        }
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
