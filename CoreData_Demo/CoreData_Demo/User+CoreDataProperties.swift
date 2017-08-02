//
//  User+CoreDataProperties.swift
//  CoreData_Demo
//
//  Created by zhangteng709 on 2017/7/23.
//  Copyright © 2017年 zhangteng709. All rights reserved.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var name: String?
    @NSManaged public var phone: String?

}
