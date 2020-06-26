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

class AppDelegate: UIResponder, UIApplicationDelegate {

  // MARK: Properties
  var window: UIWindow?
  let coreDataStack = CoreDataStack()
  
  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    let storyboard = UIStoryboard(name: "Main", bundle: nil) // Main is the name of storyboard
    window = UIWindow()
    window?.rootViewController = storyboard.instantiateInitialViewController()
    window?.makeKeyAndVisible()
    
    return true
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    guard let splitViewController = window?.rootViewController as? UISplitViewController,
      let navigationController = splitViewController.viewControllers.last as? UINavigationController else {
        fatalError("Application storyboard is not setup correctly, application mis-configuration")
    }

    navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
    splitViewController.delegate = self

    guard let masterNavigationController = splitViewController.viewControllers.first as? UINavigationController,
      let controller = masterNavigationController.topViewController as? MasterViewController else {
        fatalError("Application storyboard is not setup correctly, application mis-configuration")
    }

    controller.managedObjectContext = coreDataStack.mainContext
    return true
  }
}

// MARK: UISplitViewControllerDelegate
extension AppDelegate: UISplitViewControllerDelegate {

  func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
    guard let secondaryAsNavController = secondaryViewController as? UINavigationController,
      let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController,
      topAsDetailController.detailItem == nil else {
        return false
    }

    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
    return true
  }
}
