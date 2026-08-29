//
//  KeyValueEntry+CoreDataProperties.swift
//  
//
//  Created by Oscar Berggren on 9/17/25.
//
//

import Foundation
import CoreData

extension KeyValueEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyValueEntry> {
        return NSFetchRequest<KeyValueEntry>(entityName: "KeyValueEntry")
    }

    @NSManaged public var key: String?
    @NSManaged public var typeIdentifier: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var valueData: Data?

}
