//
//  Contact.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 23/12/20.
//

import Foundation
import RealmSwift

class Contact: Object {
    
    static let _partition = "contacts"
    
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var _partition: String = ""
    @objc dynamic var firstName: String = ""
    @objc dynamic var lastName: String = ""
    @objc dynamic var contactAdded: Date?
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    convenience init(partition: String) {
        self.init()
        self._partition = partition
    }

}

class Usuario: Object {

    @objc dynamic var _id: String = ""
    @objc dynamic var _partition: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var email: String = ""
    @objc dynamic var providerType: String = ""

    override class func primaryKey() -> String {
        return "_id"
    }

}
