//
//  EmployeeDirectory.swift
//  EmployeeDirectory
//
//  Created by Richard Turton on 01/08/2014.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import Foundation
import CoreData

class EmployeeDirectory: NSManagedObject {

    @NSManaged var amount: NSNumber
    @NSManaged var date: NSDate
    @NSManaged var employee: EmployeeDirectory.Employee

}
