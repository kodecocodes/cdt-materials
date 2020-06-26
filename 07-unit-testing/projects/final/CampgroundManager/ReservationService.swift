/// Copyright (c) 2019 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import CoreData

public final class ReservationService {

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
extension ReservationService {

  public func reserveCampSite(_ campSite: CampSite, camper: Camper, date: Date, numberOfNights: Int) -> (reservation: Reservation?, error: NSError?)  {
    let reservation = Reservation(context: managedObjectContext)
    reservation.camper = camper
    reservation.campSite = campSite
    reservation.dateFrom = date

    var dateComponents = DateComponents()
    dateComponents.day = numberOfNights

    let calendar = Calendar.current
    let toDate = calendar.date(byAdding: dateComponents, to: date)
    reservation.dateTo = toDate

    // Some complex logic here to determine if reservation is valid or if there are conflicts
    var registrationError: NSError? = nil

    if numberOfNights <= 0 {
      reservation.status = "Invalid"
      registrationError = NSError(domain: "CampingManager",
                                  code: 5,
                                  userInfo: ["Problem": "Invalid number of days"])
    } else {
      reservation.status = "Reserved"
    }
    coreDataStack.saveContext(managedObjectContext)

    // Error here would be a custom error to explain a failed reservation possibly
    return (reservation, registrationError)
  }
}
