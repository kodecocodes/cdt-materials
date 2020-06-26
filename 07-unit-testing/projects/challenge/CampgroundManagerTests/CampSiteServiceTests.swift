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

import UIKit
import XCTest
import CampgroundManager
import CoreData

class CampSiteServiceTests: XCTestCase {

  // MARK: Properties
  var campSiteService: CampSiteService!
  var coreDataStack: CoreDataStack!

  override func setUp() {
    super.setUp()

    coreDataStack = TestCoreDataStack()
    campSiteService = CampSiteService(
      managedObjectContext: coreDataStack.mainContext,
      coreDataStack: coreDataStack)
  }

  override func tearDown() {
    super.tearDown()

    campSiteService = nil
    coreDataStack = nil
  }

  func testRootContextIsSavedAfterAddingCampsite() {
    let derivedContext = coreDataStack.newDerivedContext()

    campSiteService = CampSiteService(
      managedObjectContext: derivedContext,
      coreDataStack: coreDataStack)

    expectation(
      forNotification: .NSManagedObjectContextDidSave,
      object: coreDataStack.mainContext) {
        notification in
        return true
    }

    derivedContext.perform {
      let campSite = self.campSiteService.addCampSite(1, electricity: true, water: true)
      XCTAssertNotNil(campSite)
    }

    waitForExpectations(timeout: 2.0) { error in
      XCTAssertNil(error, "Save did not occur")
    }
  }

  func testAddCampSite() {
    let campSite = campSiteService.addCampSite(1, electricity: true, water: true)

    XCTAssertTrue(campSite.siteNumber == 1, "Site number should be 1")
    XCTAssertTrue(campSite.electricity!.boolValue, "Site should have electricity")
    XCTAssertTrue(campSite.water!.boolValue, "Site should have water")
  }

  func testGetCampSiteNoSites() {
    let campSite = campSiteService?.getCampSite(1)

    XCTAssertNil(campSite, "No campsite should be returned")
  }

  func testGetCampSiteWithMatchingSiteNumber() {
    _ = campSiteService.addCampSite(1,
                                    electricity: true,
                                    water: true)

    let campSite = campSiteService.getCampSite(1)
    XCTAssertNotNil(campSite, "A campsite should be returned")
  }

  func testGetCampSiteNoMatchingSiteNumber() {
    _ = campSiteService.addCampSite(1,
                                    electricity: true,
                                    water: true)

    let campSite = campSiteService.getCampSite(2)
    XCTAssertNil(campSite, "No campsite should be returned")
  }

  func testGetCampSitesNoSites() {
    let sites = campSiteService.getCampSites()

    XCTAssertTrue(sites.count == 0, "There should be no sites.")
  }

  func testGetCampSitesOneSite() {
    _ = campSiteService.addCampSite(1,
                                    electricity: true,
                                    water: true)

    let sites = campSiteService.getCampSites()

    XCTAssertTrue(sites.count == 1, "There should be one site.")
  }

  func testGetCampSitesMultipleSite() {
    _ = campSiteService.addCampSite(1,
                                    electricity: true,
                                    water: true)
    _ = campSiteService.addCampSite(2,
                                    electricity: true,
                                    water: true)

    let sites = campSiteService?.getCampSites()

    XCTAssertTrue(sites?.count == 2, "There should be two sites.")
  }

  func testDeleteCampSite() {
    _ = campSiteService.addCampSite(1,
                                    electricity: true,
                                    water: true)

    var fetchedCampSite = campSiteService.getCampSite(1)

    XCTAssertNotNil(fetchedCampSite, "Site should exist")

    campSiteService.deleteCampSite(1)

    fetchedCampSite = campSiteService.getCampSite(1)

    XCTAssertNil(fetchedCampSite, "Site shouldn't exist")
  }

  func testGetNextCampSiteNumberNoSites() {
    let siteNumber = campSiteService.getNextCampSiteNumber()

    XCTAssertTrue(siteNumber == 1, "This should be the first campsite number")
  }

  func testGetNextCampSiteNumberOneSite() {
    _ = campSiteService.addCampSite(1,
                                    electricity: true,
                                    water: true)

    let siteNumber = campSiteService.getNextCampSiteNumber()

    XCTAssertTrue(siteNumber == 2, "This should be the second campsite number")
  }

  func testGetNextCampSiteNumberOneSiteGapFrom1() {
    _ = campSiteService.addCampSite(10,
                                    electricity: true,
                                    water: true)
    let siteNumber = campSiteService.getNextCampSiteNumber()

    XCTAssertTrue(siteNumber == 11, "This should be the second campsite number")
  }

  func testGetNextCampSiteNumberMultipleSites() {
    _ = campSiteService.addCampSite(1,
                                    electricity: true,
                                    water: true)
    _ = campSiteService.addCampSite(10,
                                    electricity: true,
                                    water: true)
    _ = campSiteService.addCampSite(30,
                                    electricity: true,
                                    water: true)
    _ = campSiteService.addCampSite(31,
                                    electricity: true,
                                    water: true)

    let siteNumber = campSiteService.getNextCampSiteNumber()

    XCTAssertTrue(siteNumber == 32, "This should be the fifth campsite number")
  }
}
