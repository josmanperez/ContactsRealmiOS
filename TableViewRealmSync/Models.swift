//
//  Contact.swift
//  TableViewRealmSync
//
//  Created by Josman Pedro Pérez Expósito on 23/12/20.
//

import Foundation
import RealmSwift

class Contact: Object {
    
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var _partition: String = ""
    @objc dynamic var firstName: String = ""
    @objc dynamic var lastName: String = ""
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    convenience init(partition: String, name: String) {
        self.init()
        self._partition = partition
    }

}
