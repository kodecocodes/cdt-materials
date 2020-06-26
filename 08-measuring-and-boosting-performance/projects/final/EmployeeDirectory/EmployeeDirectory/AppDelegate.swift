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
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  lazy var coreDataStack = CoreDataStack(modelName: "EmployeeDirectory")

  let amountToImport = 50
  let addSalesRecords = true

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {

    importJSONSeedDataIfNeeded()

    guard let tabController = window?.rootViewController as? UITabBarController,
      let employeeListNavigationController = tabController.viewControllers?[0] as? UINavigationController,
      let employeeListViewController = employeeListNavigationController.topViewController as? EmployeeListViewController else {
        fatalError("Application storyboard mis-configuration. Application is mis-configured")
    }

    employeeListViewController.coreDataStack = coreDataStack

    guard let departmentListNavigationController = tabController.viewControllers?[1] as? UINavigationController,
      let departmentListViewController = departmentListNavigationController.topViewController as? DepartmentListViewController else {
        fatalError("Application storyboard mis-configuration. Application is mis-configured")
    }

    departmentListViewController.coreDataStack = coreDataStack

    return true
  }

  func applicationWillTerminate(_ application: UIApplication) {
    coreDataStack.saveContext()
  }
}

// MARK: Data Import
extension AppDelegate {

  func importJSONSeedDataIfNeeded() {
    var importRequired = false

    let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()

    var employeeCount = -1
    do {
      employeeCount = try coreDataStack.mainContext.count(for: fetchRequest)
    } catch {
      print("ERROR: employee count failed")
    }

    if employeeCount != amountToImport {
      importRequired = true
    }

    if !importRequired,
      addSalesRecords {
      let salesFetch: NSFetchRequest<Sale> = Sale.fetchRequest()

      var salesCount = -1
      do {
        salesCount = try coreDataStack.mainContext.count(for: salesFetch)
      } catch {
        print("Error: sales count failed")
      }
      if salesCount == 0 {
        importRequired = true
      }
    }

    if importRequired {

      let deleteRequest = NSBatchDeleteRequest(fetchRequest: Employee.fetchRequest())
      deleteRequest.resultType = .resultTypeCount

      let deletedObjectCount: Int
      do {
        let resultBox = try coreDataStack.mainContext.execute(deleteRequest) as! NSBatchDeleteResult
        deletedObjectCount = resultBox.result as! Int
      } catch let nserror as NSError {
        print("Error: \(nserror.localizedDescription)")
        abort()
      }

      print("Removed \(deletedObjectCount) objects.")
      coreDataStack.saveContext()
      let records = max(0, min(500, amountToImport))
      importJSONSeedData(records)
    }
  }

  func importJSONSeedData(_ records: Int) {

    let jsonURL = Bundle.main.url(forResource: "seed", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)

    var jsonArray: [[String: AnyObject]] = []
    do {
      jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [[String: AnyObject]]
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
      abort()
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    var counter = 0
    for jsonDictionary in jsonArray {

      counter += 1

      let guid = jsonDictionary["guid"] as! String
      let active = jsonDictionary["active"] as! Bool
      let name = jsonDictionary["name"] as! String
      let vacationDays = jsonDictionary["vacationDays"] as! Int
      let department = jsonDictionary["department"] as! String
      let startDate = jsonDictionary["startDate"] as! String
      let email = jsonDictionary["email"] as! String
      let phone = jsonDictionary["phone"] as! String
      let address = jsonDictionary["address"] as! String
      let about = jsonDictionary["about"] as! String
      let picture = jsonDictionary["picture"] as! String
      let pictureComponents = picture.components(separatedBy: ".")
      let pictureFileName = pictureComponents[0]
      let pictureFileExtension = pictureComponents[1]
      let pictureURL = Bundle.main.url(forResource: pictureFileName,
                                       withExtension: pictureFileExtension)!
      let pictureData = try! Data(contentsOf: pictureURL)

      let employee = Employee(context: coreDataStack.mainContext)
      employee.guid = guid
      employee.active = NSNumber(value: active)
      employee.name = name
      employee.vacationDays = NSNumber(value: vacationDays)
      employee.department = department
      employee.startDate = dateFormatter.date(from: startDate)
      employee.email = email
      employee.phone = phone
      employee.address = address
      employee.about = about
      employee.pictureThumbnail =
        imageDataScaledToHeight(pictureData, height: 120)

      let pictureObject =
        EmployeePicture(context: coreDataStack.mainContext)
      pictureObject.picture = pictureData
      employee.picture = pictureObject

      if addSalesRecords {
        addSalesRecordsToEmployee(employee)
      }

      if counter == records {
        break
      }

      if counter % 20 == 0 {
        coreDataStack.saveContext()
        coreDataStack.mainContext.reset()
      }
    }

    coreDataStack.saveContext()
    coreDataStack.mainContext.reset()
    print("Imported \(counter) employees.")
  }

  func imageDataScaledToHeight(_ imageData: Data, height: CGFloat) -> Data {

    let image = UIImage(data: imageData)!
    let oldHeight = image.size.height
    let scaleFactor = height / oldHeight
    let newWidth = image.size.width * scaleFactor
    let newSize = CGSize(width: newWidth, height: height)
    let newRect = CGRect(x: 0, y: 0, width: newWidth, height: height)

    UIGraphicsBeginImageContext(newSize)
    image.draw(in: newRect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage!.jpegData(compressionQuality: 0.8)!
  }

  func addSalesRecordsToEmployee(_ employee: Employee) {
    let numberOfSales = 1000 + arc4random_uniform(5000)
    for _ in 0...numberOfSales {
      let sale = Sale(context: coreDataStack.mainContext)
      sale.employee = employee
      sale.amount = NSNumber(value: 3000 + arc4random_uniform(20000))
    }
    print("added \(String(describing: employee.sales?.count)) sales")
  }
}
