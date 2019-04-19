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
Natural desire is to handle pan's delegate methods in our code and just block it from recognizing whenever a suitable horizontal swipe is detected. But when you try to assign a delegate, an exception is thrown telling that it's prohibited (if you wrap it in try/catch, then your supplied delegate is simply not set). This `panGestureRecognizer` is a private subclass of `UIPanGestureRecognizer`, so it looks that `-setDelegate:` is overridden...

`UIKit` lives in dynamic world of Objective-C, so we can replace method implementations using technique called "method swizzling"! Let's simply replace the nasty exception with a normal `-setDelegate:` call of `UIGestureRecognizer` (well, simply a superclass of `panGestureRecognizer` is enough). In Swift it looks [far from trivial](https://github.com/kambala-decapitator/SwipeToDeleteInsidePageVC/blob/master/SwipeToDeleteInsidePageVC/AppDelegate.swift#L32)...

#### Objective-C implementation
In objc achieving the same is so much easier, because it's just a superset of the C language:

    @import ObjectiveC.message;

    void swizzle_setScrollViewPanRecognizerDelegate(id self, SEL _cmd, id<UIGestureRecognizerDelegate> delegate) {
        // ENABLE_STRICT_OBJC_MSGSEND setting prohibits normal calls to objc_msgSend's family, so casting to appropriate type is required first
        typedef void (*objc_msgSend_type)(struct objc_super *super, SEL op, __typeof__(delegate));
        objc_msgSend_type objc_msgSendSuper_withParams = (objc_msgSend_type)objc_msgSendSuper;

        struct objc_super superInfo = {
            .receiver = self,
            .super_class = [self superclass]
        };
        objc_msgSendSuper_withParams(&superInfo, _cmd, delegate);
    }

    ...

    // `pan` is the scrollview's `panGestureRecognizer`
    method_setImplementation(class_getInstanceMethod([pan class], @selector(setDelegate:)), (IMP)swizzle_setScrollViewPanRecognizerDelegate);
