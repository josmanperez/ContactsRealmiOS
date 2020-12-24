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
    
    let app = App(id: "mindme-lqkmq")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        connect()
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
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = "Hola"
        return cell
        
    }
    
    
    
}

