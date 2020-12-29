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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        //readFromDB()
        connect()
    }
    
    deinit {
        self.notificationToken?.invalidate()
    }
    
    func readFromDB() {
        do {
            contacts = try Realm().objects(Contact.self)
            tableView.reloadData()
        } catch (let error) {
            debugPrint(error.localizedDescription)
        }
    }
    
    /// Initial configuration for the tableView
    func configureTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func connect() {
        app.login(credentials: Credentials.anonymous) { result in
            switch result {
            case .success(let user):
                debugPrint("Login as \(user) succeded!")
                self.openRealm(user: user)
            case .failure(let error):
                debugPrint("Login failed: \(error.localizedDescription)")
            }
            
        }
    }
    
    func openRealm(user: User) {
        //let client = user.mongoClient("mongodb-atlas")
        //let database = client.database(named: "mindMe")
        //let collection = database.collection(withName: "Contacts")
        //debugPrint(collection)
        var configuration = user.configuration(partitionValue: Contact._partition)
        configuration.objectTypes = [Contact.self]
        
        Realm.asyncOpen(configuration: configuration) { (result) in
            switch result {
            case .failure(let error):
                debugPrint("Failed to open realm: \(error.localizedDescription)")
            case .success(let realm):
                self.contacts = realm.objects(Contact.self)
                self.notificationToken = self.contacts?.observe{ [weak self] (changes: RealmCollectionChange) in
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
                self.tableView.reloadData()
                debugPrint(self.contacts ?? "Empty")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContactDetail" {
            if let vc = segue.destination as? ContactViewController, let contact = sender as? Contact {
                vc.contact = contact
                vc.delegate = self
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
        cell.textLabel?.text = "\(_contacts[indexPath.row].firstName) \(_contacts[indexPath.row].lastName)"
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let _contact = contacts?[indexPath.row] else { return }
            do {
                let realm = try Realm()
                try realm.write {
                    realm.delete(_contact)
                }
                tableView.deleteRows(at: [indexPath], with: .fade)
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

