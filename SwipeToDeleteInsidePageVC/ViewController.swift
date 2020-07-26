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
    let isRightToLeftCellSwipeEnabled: Bool // left-to-right otherwise


    init(_ text: String, isRightToLeft: Bool) {
        cellText = text
        isRightToLeftCellSwipeEnabled = isRightToLeft
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }

    func shouldAllowTableSwipeWithRecognizer(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // right-to-left swipe is for UITableView's swipe-to-delete, left-to-right - for custom cell actions on the left
        let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let horizontalVelocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view).x
        guard (isRightToLeftCellSwipeEnabled && horizontalVelocity < 0) || (!isRightToLeftCellSwipeEnabled && horizontalVelocity > 0) else { return false }
        // handle table swipe only on actual data
        return tableView.indexPathForRow(at: panGestureRecognizer.location(in: tableView)) != nil
    }

    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount
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
        return isRightToLeftCellSwipeEnabled ? .delete : .none
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isRightToLeftCellSwipeEnabled else {
            return nil
        }
        return UISwipeActionsConfiguration(actions: [UIContextualAction(style: .normal, title: "action", handler: { (action, sourceView, completion) in
            print("triggered \(action) in \(sourceView)")
            completion(true)
        })])
    }
}
