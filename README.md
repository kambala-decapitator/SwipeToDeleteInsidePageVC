# SwipeToDeleteInsidePageVC
Fixing `UITableView`'s swipe-to-delete gesture inside horizontal `UIPageViewController` with runtime magic.

If you place a `UITableView` in a `UIPageViewController`'s page, then you'll notice that it's quite difficult to make the table trigger swipe action in a cell (e.g. classic swipe-to-delete or custom actions on the left/right). The reason is that `UIPageViewController`->`UIView`->`UIScrollView`->`UIPanGestureRecognizer` handles all horizontal interactions and doesn't let the gesture go deeper.

#### Quick win attempts
1. Just replace `UIPageViewController` with a custom paging class (pretty sure there's a number of open-source implementations) --- this way you have full control over its gesture recognizer(s) and can easily modify to suit your needs. But we're interested in using default class :)
2. `bounces = false` on `UIScrollView`. If the table is on the right edge and you want swipe-to-delete, then you might think "let's just disable bouncing"! But no: swiping between pages gets completely killed.
3. `UITableView` is also a `UIScrollView`, so it also has `panGestureRecognizer`, so let's just require from `UIPageViewController`'s pan that `UITableView`'s pan must fail first! Too bad: you can't swipe back from `UITableView` then.
4. (not-so-quick) OK, so maybe `UITableView` has some other specific recognizer? Let's check:

        (
        <UIScrollViewDelayedTouchesBeganGestureRecognizer: 0x600001d41600; state = Possible; delaysTouchesBegan = YES; view = <UITableView 0x7fc1c4018a00>; target= <(action=delayed:, target=<UITableView 0x7fc1c4018a00>)>>,
        <UIScrollViewPanGestureRecognizer: 0x7fc1c2d00db0; state = Possible; delaysTouchesEnded = NO; view = <UITableView 0x7fc1c4018a00>; target= <(action=handlePan:, target=<UITableView 0x7fc1c4018a00>)>>,
        <_UIDragAutoScrollGestureRecognizer: 0x60000181b9c0; state = Possible; cancelsTouchesInView = NO; delaysTouchesEnded = NO; view = <UITableView 0x7fc1c4018a00>; target= <(action=_handleAutoScroll:, target=<UITableView 0x7fc1c4018a00>)>>,
        <_UISwipeActionPanGestureRecognizer: 0x7fc1c2e068f0; state = Possible; view = <UITableView 0x7fc1c4018a00>; target= <(action=_swipeRecognizerDidRecognize:, target=<UISwipeHandler 0x600000a46bc0>)>>,
        <UISwipeDismissalGestureRecognizer: 0x600001e46df0; state = Possible; enabled = NO; delaysTouchesBegan = YES; view = <UITableView 0x7fc1c4018a00>; target= <(action=_dismissalRecognizerDidRecognize:, target=<UISwipeHandler 0x600000a46bc0>)>>
        )

`_UISwipeActionPanGestureRecognizer` looks just what we want! But it's a private class, so there's no guarantee that it doesn't change in future. Also, you'd have to test all major (at least!) iOS versions to verify that the class isn't renamed. Maybe same approach as in 3 would work, but I haven't tested it.

### My solution
[Old solution through `-setDelegate:` swizzling](https://github.com/kambala-decapitator/SwipeToDeleteInsidePageVC/tree/4387944e4ec06376809eec4a559ae2ee3616cfc7)

An obvious solution is to simply block scrollview's pan gesture from recognizing. Since `UIKit` lives in dynamic world of Objective-C, we can replace method implementations using technique called "method swizzling"! So let's simply inspect pan delegate's `-gestureRecognizerShouldBegin:` and ignore original implementation if suitable horizontal pan is detected (left-to-right, right-to-left, whatever you need): [swizzling code](https://github.com/kambala-decapitator/SwipeToDeleteInsidePageVC/blob/master/SwipeToDeleteInsidePageVC/AppDelegate.swift#L38)

#### Open questions
But what if you want to enable swipe-to-delete on a left table? It'd interfere with swiping to a right page by default, so you'd need another way of allowing that (e.g. Edit button, but for deleting it's easier to just enable the defaul edit mode with red "minus" buttons). In such case it'd probably be much easier to simply disable the `panGestureRecognizer` and re-enable it after user finished editing.
