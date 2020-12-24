//
//  ViewController.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 23/12/20.
//

import UIKit
import RealmSwift
import Realm

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var contacts:Results<Contact>?
    let app = App(id: "mindme-lqkmq")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        readFromDB()
        //connect()
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
        let client = user.mongoClient("mongodb-atlas")
        let database = client.database(named: "mindMe")
        let collection = database.collection(withName: "Contacts")
        debugPrint(collection)
        let partitionValue = "AccountId"
        var configuration = user.configuration(partitionValue: partitionValue)
        configuration.objectTypes = [Contact.self]
        
                
        Realm.asyncOpen() { (result) in
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error.localizedDescription)")
            // Handle error...
            case .success(let realm):
                let contacts = realm.objects(Contact.self)
                debugPrint(contacts)
                // Get all tasks in the realm
                //let tasks = realm.objects(ContactTest.self)
                // Retain notificationToken as long as you want to observe

            }
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
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
    
    
    
}

