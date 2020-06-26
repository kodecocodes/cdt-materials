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

class CamperServiceTests: XCTestCase {
  
  // MARK: Properties
  var camperService: CamperService!
  var coreDataStack: CoreDataStack!
  
  override func setUp() {
    super.setUp()
    
    coreDataStack = TestCoreDataStack()
    camperService = CamperService(
      managedObjectContext: coreDataStack.mainContext,
      coreDataStack: coreDataStack)
  }
  
  override func tearDown() {
    super.tearDown()
    
    coreDataStack = nil
    camperService = nil
  }
  
  func testRootContextIsSavedAfterAddingCamper() {
    let derivedContext = coreDataStack.newDerivedContext()
    camperService = CamperService(managedObjectContext: derivedContext,
                                  coreDataStack: coreDataStack)
    
    expectation(
      forNotification: .NSManagedObjectContextDidSave,
      object: coreDataStack.mainContext) {
        notification in
        return true
    }
    
    derivedContext.perform {
      let camper = self.camperService.addCamper("Bacon Lover",
                                                phoneNumber: "910-543-9000")
      XCTAssertNotNil(camper)
    }
    
    waitForExpectations(timeout: 2.0) { error in
      XCTAssertNil(error, "Save did not occur")
    }
  }
  
  func testAddCamper() {
    
    let camper = camperService.addCamper("Bacon Lover",
                                         phoneNumber: "910-543-9000")
    
    XCTAssertNotNil(camper, "Camper should not be nil")
    XCTAssertTrue(camper?.fullName == "Bacon Lover")
    XCTAssertTrue(camper?.phoneNumber == "910-543-9000")
  }
}
