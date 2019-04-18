//
//  AppDelegate.swift
//  SwipeToDeleteInsidePageVC
//
//  Created by Andrey Filipenkov on 18/04/2019.
//  Copyright © 2019 kambala. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let centralVc = UIViewController()
    let leftTable = ViewController("left")
    let rightTable = ViewController("right")


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = {
            let pageVc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
            pageVc.dataSource = self
            pageVc.setViewControllers([self.centralVc], direction: .forward, animated: false, completion: nil)
            return pageVc
        }()
        window?.makeKeyAndVisible()

        centralVc.view.backgroundColor = UIColor.lightGray
        return true
    }
}

// MARK: - UIPageViewControllerDataSource
extension AppDelegate: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        switch viewController {
        case leftTable:
            return centralVc
        case centralVc:
            return rightTable
        default:
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        switch viewController {
        case rightTable:
            return centralVc
        case centralVc:
            return leftTable
        default:
            return nil
        }
    }
}
