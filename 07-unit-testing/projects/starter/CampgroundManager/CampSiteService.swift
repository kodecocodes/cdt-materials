/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import CoreData

public final class CampSiteService {
  // MARK: Properties
  let managedObjectContext: NSManagedObjectContext
  let coreDataStack: CoreDataStack

  // MARK: Initializers
  public init(managedObjectContext: NSManagedObjectContext, coreDataStack: CoreDataStack) {
    self.managedObjectContext = managedObjectContext
    self.coreDataStack = coreDataStack
  }
}

// MARK: Public
extension CampSiteService {
  public func addCampSite(_ siteNumber: NSNumber, electricity: Bool, water: Bool) -> CampSite {
    let campSite = CampSite(context: managedObjectContext)
    campSite.siteNumber = siteNumber
    campSite.electricity = NSNumber(value: electricity)
    campSite.water = NSNumber(value: water)

    coreDataStack.saveContext(managedObjectContext)

    return campSite
  }

  public func deleteCampSite(_ siteNumber: NSNumber) {
    // TODO : Not yet implemented
  }

  public func getCampSite(_ siteNumber: NSNumber) -> CampSite? {
    // TODO : Not yet implemented

    return nil
  }

  public func getCampSites() -> [CampSite] {
    let fetchRequest: NSFetchRequest<CampSite> = CampSite.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "siteNumber", ascending: true)]

    var results: [CampSite]
    do {
      try results = managedObjectContext.fetch(fetchRequest)
    } catch {
      results = []
    }

    return results
  }

  public func getNextCampSiteNumber() -> NSNumber {
    let sites = getCampSites()

    if !sites.isEmpty,
      let lastSiteNumber = sites.last?.siteNumber {
        return NSNumber(value: lastSiteNumber.intValue + 1)
    }

    return 1
  }
}
