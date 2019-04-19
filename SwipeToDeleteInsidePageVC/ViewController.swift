//
//  ViewController.swift
//  SwipeToDeleteInsidePageVC
//
//  Created by Andrey Filipenkov on 18/04/2019.
//  Copyright © 2019 kambala. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    var cellCount = 10
    let cellIdentifier = "cell"
    let cellText: String


    init(_ text: String) {
        cellText = text
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }

    func originalPanDelegate() -> UIGestureRecognizerDelegate {
        return (UIApplication.shared.delegate as! AppDelegate).pageVcScrollViewPanRecognizerOriginalDelegate
    }

    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = cellText
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        cellCount -= 1
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return originalPanDelegate().gestureRecognizer!(gestureRecognizer, shouldReceive: touch)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // right-to-left swipe is for UITableView's swipe-to-delete
        let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        guard panGestureRecognizer.velocity(in: panGestureRecognizer.view).x < 0 else {
            return originalPanDelegate().gestureRecognizerShouldBegin!(gestureRecognizer)
        }
        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return originalPanDelegate().gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return originalPanDelegate().gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) ?? false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return originalPanDelegate().gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) ?? false
    }
}
