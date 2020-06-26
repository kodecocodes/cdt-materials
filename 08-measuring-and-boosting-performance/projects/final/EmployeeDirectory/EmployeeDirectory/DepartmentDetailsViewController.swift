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

class DepartmentDetailsViewController: UIViewController {

  // MARK: Properties
  var coreDataStack: CoreDataStack!

  var department: String?

  // MARK: IBOutlets
  @IBOutlet var totalEmployeesLabel: UILabel!
  @IBOutlet var activeEmployeesLabel: UILabel!
  @IBOutlet var greaterThanFifteenVacationDaysLabel: UILabel!
  @IBOutlet var greaterThanTenVacationDaysLabel: UILabel!
  @IBOutlet var greaterThanFiveVacationDaysLabel: UILabel!
  @IBOutlet var greaterThanZeroVacationDaysLabel: UILabel!
  @IBOutlet var zeroVacationDaysLabel: UILabel!
  
  // MARK: View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    configureView()
  }
}

// MARK: Internal
extension DepartmentDetailsViewController {

  func configureView() {
    guard let department = department else { return }

    title = department

    totalEmployeesLabel.text = totalEmployees(department)
    activeEmployeesLabel.text = activeEmployees(department)

    greaterThanFifteenVacationDaysLabel.text =
      greaterThanVacationDays(15, department: department)

    greaterThanTenVacationDaysLabel.text =
      greaterThanVacationDays(10, department: department)

    greaterThanFiveVacationDaysLabel.text =
      greaterThanVacationDays(5, department: department)

    greaterThanZeroVacationDaysLabel.text =
      greaterThanVacationDays(0, department: department)

    zeroVacationDaysLabel.text = zeroVacationDays(department)
  }

  func totalEmployees(_ department: String) -> String {
    let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "%K = %@",
                                         argumentArray: [#keyPath(Employee.department),
                                                         department])

    do {
      let results = try coreDataStack.mainContext.fetch(fetchRequest)
      return String(results.count)
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
      return "0"
    }
  }

  func activeEmployees(_ department: String) -> String {
    let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "%K = %@ AND %@ = YES",
                                         argumentArray: [#keyPath(Employee.department),
                                                         department,
                                                         #keyPath(Employee.active)])

    do {
      let results = try coreDataStack.mainContext.fetch(fetchRequest)
      return String(results.count)
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
      return "0"
    }
  }

  func greaterThanVacationDays(_ vacationDays: Int, department: String) -> String {
    let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "%K = %@ AND %K > %@",
                                         argumentArray: [#keyPath(Employee.department),
                                                         department,
                                                         #keyPath(Employee.vacationDays),
                                                         NSNumber(value: vacationDays)])

    do {
      let results = try coreDataStack.mainContext.fetch(fetchRequest)
      return String(results.count)
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
      return "0"
    }
  }

  func zeroVacationDays(_ department: String) -> String {
    let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "%K = %@ AND %K = 0",
                                         argumentArray: [#keyPath(Employee.department),
                                                         department,
                                                         #keyPath(Employee.vacationDays)])

    do {
      let results = try coreDataStack.mainContext.fetch(fetchRequest)
      return String(results.count)
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
      return "0"
    }
  }
}
