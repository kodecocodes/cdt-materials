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

class DepartmentListViewController: UITableViewController {

  // MARK: - Properties
  var coreDataStack: CoreDataStack!
  var items: [[String: String]] = []

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    items = totalEmployeesPerDepartmentFast()
  }

  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    if segue.identifier == "SegueDepartmentListToDepartmentDetails" {

      guard let tableViewCell = sender as? UITableViewCell,
        let indexPath = tableView.indexPath(for: tableViewCell),
        let controller = segue.destination as? DepartmentDetailsViewController else {
          return
      }

      let departmentDictionary = items[indexPath.row]
      let department = departmentDictionary["department"]

      controller.coreDataStack = coreDataStack
      controller.department = department

    } else if segue.identifier == "SegueDepartmentsListToEmployeeList" {

      guard let indexPath = tableView.indexPathForSelectedRow,
        let controller = segue.destination as? EmployeeListViewController else {
          return
      }

      let departmentDictionary = items[indexPath.row]
      let department = departmentDictionary["department"]

      controller.coreDataStack = coreDataStack
      controller.department = department
    }
  }
}

// MARK: - Internal
extension DepartmentListViewController {

  func totalEmployeesPerDepartment() -> [[String: String]] {

    // 1
    let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
    
    var fetchResults: [Employee] = []
    do {
      fetchResults = try coreDataStack.mainContext.fetch(fetchRequest)
    } catch let error as NSError {
      print("ERROR: \(error.localizedDescription)")
      return [[String: String]]()
    }
    
    // 2
    var uniqueDepartments: [String: Int] = [:]
    for employee in fetchResults where employee.department != nil {
      uniqueDepartments[employee.department!, default: 0] += 1
    }
    
    // 3
    return uniqueDepartments.map { (department, headCount) in
      ["department": department,
       "headCount": String(headCount)]
    }
  }

  func totalEmployeesPerDepartmentFast() -> [[String: String]] {
    //1
    let expressionDescription = NSExpressionDescription()
    expressionDescription.name = "headCount"
    //2
    let arguments = [NSExpression(forKeyPath: "department")]
    expressionDescription.expression =
      NSExpression(forFunction: "count:",
                   arguments: arguments)
    //3
    let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "Employee")
    fetchRequest.propertiesToFetch = ["department", expressionDescription]
    fetchRequest.propertiesToGroupBy = ["department"]
    fetchRequest.resultType = .dictionaryResultType
    //4
    var fetchResults: [NSDictionary] = []
    do {
      fetchResults =
        try coreDataStack.mainContext.fetch(fetchRequest)
    } catch let error as NSError {
      print("ERROR: \(error.localizedDescription)")
      return []
    }
    return fetchResults as! [[String: String]]
  }
}

// MARK: - UITableViewDataSource
extension DepartmentListViewController {

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let departmentDictionary: [String: String] = items[indexPath.row]

    let cell = tableView.dequeueReusableCell(withIdentifier: "DepartmentCellReuseIdentifier",
                                             for: indexPath)

    cell.textLabel?.text = departmentDictionary["department"]
    cell.detailTextLabel?.text = departmentDictionary["headCount"]

    return cell
  }
}
