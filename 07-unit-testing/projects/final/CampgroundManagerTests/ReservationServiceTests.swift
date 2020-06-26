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
import XCTest
import CampgroundManager

class ReservationServiceTests: XCTestCase {

  // MARK: Properties
  var campSiteService: CampSiteService!
  var camperService: CamperService!
  var reservationService: ReservationService!
  var coreDataStack: CoreDataStack!

  override func setUp() {
    super.setUp()

    coreDataStack = TestCoreDataStack()
    camperService = CamperService(
      managedObjectContext: coreDataStack.mainContext,
      coreDataStack: coreDataStack)
    campSiteService = CampSiteService(
      managedObjectContext: coreDataStack.mainContext,
      coreDataStack: coreDataStack)
    reservationService = ReservationService(
      managedObjectContext: coreDataStack.mainContext,
      coreDataStack: coreDataStack)
  }

  override func tearDown() {
    super.tearDown()

    camperService = nil
    campSiteService = nil
    reservationService = nil
    coreDataStack = nil
  }

  func testReserveCampSitePositiveNumberOfDays() {
    let camper = camperService.addCamper("Johnny Appleseed",
                                         phoneNumber: "408-555-1234")!
    let campSite = campSiteService.addCampSite(15,
                                               electricity: false,
                                               water: false)

    let result = reservationService.reserveCampSite(campSite,
                                                    camper: camper,
                                                    date: Date(),
                                                    numberOfNights: 5)

    XCTAssertNotNil(result.reservation, "Reservation should not be nil")
    XCTAssertNil(result.error, "No error should be present")
    XCTAssertTrue(result.reservation?.status == "Reserved",
                  "Status should be Reserved")
  }

  func testReserveCampSiteNegativeNumberOfDays() {
    let camper = camperService.addCamper("Johnny Appleseed",
                                         phoneNumber: "408-555-1234")!
    let campSite = campSiteService.addCampSite(15,
                                               electricity: false,
                                               water: false)

    let result = reservationService!.reserveCampSite(campSite,
                                                     camper: camper,
                                                     date: Date(),
                                                     numberOfNights: -1)

    XCTAssertNotNil(result.reservation, "Reservation should not be nil")
    XCTAssertNotNil(result.error, "No error should be present")
    XCTAssertTrue(result.error?.userInfo["Problem"] as? String
      == "Invalid number of days", "Error problem should be present")
    XCTAssertTrue(result.reservation?.status == "Invalid", "Status should be Invalid")
  }
}
