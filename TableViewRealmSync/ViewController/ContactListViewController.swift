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
    var realm: Realm?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        //readFromDB()
        connect()
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
        let partitionValue = Contact._partition
        var configuration = user.configuration(partitionValue: partitionValue)
        configuration.objectTypes = [Contact.self]
        
        Realm.asyncOpen() { (result) in
            switch result {
            case .failure(let error):
                debugPrint("Failed to open realm: \(error.localizedDescription)")
            case .success(let realm):
                self.contacts = realm.objects(Contact.self)
                self.tableView.reloadData()
                debugPrint(self.contacts ?? "Empty")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addNewContact" {
            if let vc = segue.destination as? AddNameViewController {
                vc.delegate = self
            }
        }
        else if segue.identifier == "showContactDetail" {
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

