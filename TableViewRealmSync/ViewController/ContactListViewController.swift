//
//  ViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 23/12/20.
//

import UIKit
import RealmSwift
import Realm

protocol SaveContactDelegate {
    func onSave()
}

class ContactListViewController: UIViewController, SaveContactDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var contacts:Results<Contact>?
    var notificationToken: NotificationToken?
    var realm: Realm?
    var userData: Usuario?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureUser()
        //connect()
    }
    
    deinit {
        self.notificationToken?.invalidate()
    }
    
    func configureUser() {
        guard let user = realm?.objects(Usuario.self).first else {
            return
        }
        self.userData = user
        self.contacts = realm?.objects(Contact.self)
        self.observeForChanges()
        self.tableView.reloadData()
    }
    
    /// Initial configuration for the tableView
    func configureTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func observeForChanges() {
        self.notificationToken = self.contacts?.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                // Always apply updates in the following order: deletions, insertions, then modifications.
                // Handling insertions before deletions may result in unexpected behavior.
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    @IBAction func logOut(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Log Out", message: "", preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: "Yes, Log Out", style: .destructive, handler: {
            alert -> Void in
            print("Logging out...");
            app.currentUser?.logOut() { (error) in
                DispatchQueue.main.async {
                    print("Logged out!");
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContactDetail" {
            if let vc = segue.destination as? ContactViewController, let contact = sender as? Contact {
                vc.contact = contact
                vc.realm = realm
            }
        } else if segue.identifier == "addNewContact" {
            if let vc = segue.destination as? AddContactViewController {
                vc.user = userData
            }
        } else if segue.identifier == "showUserProfile" {
            if let vc = segue.destination as? ProfileViewController {
                vc.userData = userData
            }
        }
    }
    
    func onSave() {
        self.tableView.reloadData()
    }
}

extension ContactListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let _contacts = contacts else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.selectionStyle = .none
        cell.textLabel?.text = "\(_contacts[indexPath.row].firstName) \(_contacts[indexPath.row].lastName)"
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let _contact = contacts?[indexPath.row], let realm = realm else { return }
            do {
                try realm.write {
                    realm.delete(_contact)
                }
            } catch (let error) {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let contact = contacts?[indexPath.row] else { return }
        performSegue(withIdentifier: "showContactDetail", sender: contact)
    }
    
}

