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
    weak var pageVcScrollViewPanRecognizerOriginalDelegate: UIGestureRecognizerDelegate!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = {
            let pageVc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
            pageVc.dataSource = self
            pageVc.delegate = self
            pageVc.setViewControllers([self.centralVc], direction: .forward, animated: false, completion: nil)
            return pageVc
        }()
        window!.makeKeyAndVisible()

        // swizzle -setDelegate: of scrollview's pan to prevent exception
        let pan = pageVcScrollViewPanRecognizer()
        pageVcScrollViewPanRecognizerOriginalDelegate = pan.delegate
        let panClass = type(of: pan)
        let superSetDelegateBlock: @convention(block) (AnyObject?, UIGestureRecognizerDelegate?) -> Void = { (this: AnyObject?, delegate: UIGestureRecognizerDelegate?) in
            // call -setDelegate: of pan's superclass
            // https://stackoverflow.com/a/54006381/1971301
            let panSuperClass: AnyClass = class_getSuperclass(panClass)!
            let superSetDelegateSelector = #selector(setter: UIPanGestureRecognizer.delegate)
            let superSetDelegateImp = class_getMethodImplementation(panSuperClass, superSetDelegateSelector)!

            typealias ObjCSetDelegateFn = @convention(c) (AnyObject, Selector, UIGestureRecognizerDelegate?) -> Void
            let setDelegateFn = unsafeBitCast(superSetDelegateImp, to: ObjCSetDelegateFn.self)
            setDelegateFn(pan, superSetDelegateSelector, delegate)
        }
        method_setImplementation(class_getInstanceMethod(panClass, #selector(setter: panClass.delegate))!,
                                 imp_implementationWithBlock(unsafeBitCast(superSetDelegateBlock, to: AnyObject.self)))

        centralVc.view.backgroundColor = UIColor.lightGray
        return true
    }

    func pageVcScrollViewPanRecognizer() -> UIPanGestureRecognizer {
        return (window!.rootViewController!.view.subviews.first as! UIScrollView).panGestureRecognizer
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

// MARK: - UIPageViewControllerDataSource
extension AppDelegate: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let currentVc = pageViewController.viewControllers?.first
        guard completed && currentVc != previousViewControllers.first else {
            return
        }

        if currentVc == rightTable {
            pageVcScrollViewPanRecognizer().delegate = rightTable
        }
        else {
            pageVcScrollViewPanRecognizer().delegate = pageVcScrollViewPanRecognizerOriginalDelegate
        }
    }
}
