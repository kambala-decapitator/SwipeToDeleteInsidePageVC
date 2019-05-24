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
    let  leftTable = ViewController("left",  isRightToLeft: false)
    let rightTable = ViewController("right", isRightToLeft: true)
    weak var gestureRecognizerShouldBeginCustomHandler: ViewController?
    weak var pageVcScrollViewPanRecognizerOriginalDelegate: UIGestureRecognizerDelegate!

    typealias ObjcGestureRecognizerShouldBeginFn = @convention(c) (AnyObject, Selector, UIGestureRecognizer) -> Bool
    var gestureRecognizerShouldBeginOriginalImp: ObjcGestureRecognizerShouldBeginFn!
    let gestureRecognizerShouldBeginSelector = #selector(UIGestureRecognizerDelegate.gestureRecognizerShouldBegin(_:))

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = {
            let pageVc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
            pageVc.dataSource = self
            pageVc.delegate = self
            pageVc.setViewControllers([self.centralVc], direction: .forward, animated: false, completion: nil)

            pageVcScrollViewPanRecognizerOriginalDelegate = (pageVc.view.subviews.first as! UIScrollView).panGestureRecognizer.delegate
            return pageVc
        }()
        window!.makeKeyAndVisible()

        // swizzle -gestureRecognizerShouldBegin: of pan's delegate
        let gestureRecognizerShouldBeginBlock: @convention(block) (AnyObject?, UIGestureRecognizer) -> Bool = { (this: AnyObject?, gestureRecognizer: UIGestureRecognizer) in
            // only perform custom handling if the handler is set and it's pan's delegate that is called
            guard let handler = self.gestureRecognizerShouldBeginCustomHandler, (this as? UIGestureRecognizerDelegate) === self.pageVcScrollViewPanRecognizerOriginalDelegate else {
                return self.gestureRecognizerShouldBeginOriginalImp(this!, self.gestureRecognizerShouldBeginSelector, gestureRecognizer)
            }
            return !handler.shouldAllowTableSwipeWithRecognizer(gestureRecognizer)
        }
        let protocolSelector = protocol_getMethodDescription(UIGestureRecognizerDelegate.self, gestureRecognizerShouldBeginSelector, false, true).name
        let imp = method_setImplementation(class_getInstanceMethod(type(of: pageVcScrollViewPanRecognizerOriginalDelegate), protocolSelector!)!,
                                           imp_implementationWithBlock(unsafeBitCast(gestureRecognizerShouldBeginBlock, to: AnyObject.self)))
        gestureRecognizerShouldBeginOriginalImp = unsafeBitCast(imp, to: ObjcGestureRecognizerShouldBeginFn.self)

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

// MARK: - UIPageViewControllerDataSource
extension AppDelegate: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let currentVc = pageViewController.viewControllers?.first, currentVc != previousViewControllers.first else {
            return
        }
        gestureRecognizerShouldBeginCustomHandler = currentVc != centralVc ? (currentVc as! ViewController) : nil
    }
}
