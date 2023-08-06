# CGEventSupervisor

`CGEventSupervisor` offers you modernized utilities for global supervision and interception of HID events in your macOS Swift application — regardless of the application's frontmost status:

```swift
// Example: Create a global shortcut using ⌘𝗙𝟯

import Carbon;
import Foundation;
import CGEventSupervisor;

let kCGEventSubscriberGlobalShortcut = "GlobalShortcut";

CGEventSupervisor.shared.subscribe(
    as: kCGEventSubscriberGlobalShortcut,
    to: .nsEvents(.keyDown),
    using: {
        guard
            $0.modifierFlags.contains(.command),
            $0.keyCode == kVK_F3 // Provided by Carbon
        else { return }

        NSLog("Shortcut did activate.");

        $0.cancel(); // Stop event propagation
    });
```

## Install

Add the package to your project using Swift Package Manager:

```plaintext
https://github.com/stephancasas/CGEventSupervisor
```

## Usage

After importing `CGEventSupervisor` in your Swift file, you can access the singleton `CGEventSupervisor.shared` service instance to subscribe event handlers using `CGEvent` and/or `NSEvent` objects.

Subscribers are identified by a unique `String`, and can subscribe or cancel throughout the entire lifecycle of your application. For those subscribers which are persistent, it is recommended that you establish a global constant for to avoid collisions and/or memory leaks.

Use the `.subscribe(as:to:using:)` function to create a new subscription for a specified collection of events. For example, you could use the following sample to log left and right mouse clicks with their on-screen coordinates:

```swift
import Foundation;
import CGEventSupervisor;

let kCGEventSubscriberLogMouseClicks = "LogMouseClicks";

// ...

CGEventSupervisor.shared.subscribe(
    as: kCGEventSubscriberLogMouseClicks,
    to: .cgEvents(.leftMouseDown, .rightMouseDown),
    using: {
        let btn = $0.type == .leftMouseDown ? "Left" : "Right";
        NSLog("\(btn) click at \($0.location)");
    });
```

Only the specified event types will be provided to the subscriber's callback — even if you've added other subscribers which specify events of different types.

To cancel a subscriber's event subscription, call the `.cancel(subscriber:)` function using the subscriber's unique `String` identity:

```swift
import Foundation;
import CGEventSupervisor;

// ...

CGEventSupervisor.shared.cancel(
    subscriber: kCGEventSubscriberLogMouseClicks);
```

When a subscription is canceled, `CGEventSupervisor` will evaluate event subscriptions for all other subscribers and re-define the `CGEventMask` if necessary or, if no subscribers remain, the `CGEventTap` will be disabled and the `CFMachPort` will be disposed.

### `CGEvent` vs. `NSEvent`

While a `CGEventTap` is setup to provide access to events using `CGEvent`, in some cases, it makes more sense to work with `NSEvent`. The event descriptor passed to the `to:` argument of `.subscribe(as:to:using:)` can be given either as `.cgEvents(...)` or `.nsEvents(...)` — depending on your subscriber's specific needs.

## Cancelling/Intercepting HID Events

In many circumstances, such as a global keyboard shortcut, you will want your application to exclusively handle the HID event without allowing the event to propagate to the frontmost application. To this end, `CGEventSupervisor` extends both `CGEvent` and `NSEvent` with a `.cancel()` method — callable from the context of an event subscriber's callback.

Calling `.cancel()` on either event object will cause the event to cease propagation among both other event subscribers as well as propagation to the user-focused application responder.

For example, the following sample will [disable the 𝗚 keyboard key](https://youtu.be/RgBDdDdSqNE?t=158) in every application:

```swift
import Carbon;
import Foundation;
import CGEventSupervisor;

let kCGEventSubscriberDisableGKey = "DisableGKey";

// ...

CGEventSupervisor.shared.subscribe(
    as: kCGEventSubscriberDisableGKey,
    to: .nsEvents(.keyDown),
    using: { event in
        // Constant provided in Carbon
        if event.keyCode != kVK_ANSI_G { return }
        event.cancel();
    });
```

Similarly, you can use `.cancel()` on mouse events, too. For example, the following sample will prevent the user from clicking anywhere in the menubar:

```swift
import Foundation;
import CGEventSupervisor;

let kCGEventSubscriberRestrictMenubar = "RestrictMenubar";
let kDefaultMenubarRect = CGRectMake(0, 0, .greatestFiniteMagnitude, 25);

// ...

CGEventSupervisor.shared.subscribe(
    as: kCGEventSubscriberRestrictMenubar,
    to: .cgEvents(.leftMouseDown),
    using: {
        if kDefaultMenubarRect.contains($0.location) {
            $0.cancel();
        }
    });
```

## Say Hi

[Follow Stephan on X](https://x.com/stephancasas)

## License

MIT
