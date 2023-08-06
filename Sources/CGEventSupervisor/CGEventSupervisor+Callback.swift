//
//  CGEventSupervisor+Callback.swift
//  
//
//  Created by Stephan Casas on 8/6/23.
//

import Cocoa;
import Foundation;

/// The main event callback which will perform casting
/// for `CGEvent` to `NSEvent` and resolution of the
/// given opaque pointer into `CGEventSupervisor`.
///
internal func CGEventSupervisorCallback(
    _  eventTap: CGEventTapProxy,
    _ eventType: CGEventType,
    _     event: CGEvent,
    _  userData: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard
        let supervisorRef = userData
    else {
        return Unmanaged.passUnretained(event);
    }
    
    let supervisor = Unmanaged<CGEventSupervisor>
        .fromOpaque(supervisorRef)
        .takeUnretainedValue();
    
    var bubbles = true;
    for subscriber in supervisor.cgEventSubscribers.values {
        if subscriber.events.contains(event.type){
            subscriber.callback(event);
            bubbles = !event.supervisorShouldCancel;
        }
        if !bubbles { return nil }
    }
    
    /// Is the event eligible for casting to `NSEvent`?
    ///
    if event.type.rawValue > 0,
       event.type.rawValue <= kCGEventLastUniversalType.rawValue,
       supervisor.nsEventSubscribers.count > 0,
       let nsEvent = NSEvent(cgEvent: event) {
        
        for subscriber in supervisor.nsEventSubscribers.values {
            if subscriber.events.contains(event.type) {
                subscriber.callback(nsEvent);
                bubbles = !nsEvent.supervisorShouldCancel;
            }
            if !bubbles { return nil }
        }
        
    }
    
    return Unmanaged.passUnretained(event);
}

/// The last-supported universal event type in the enumerations
/// of `NSEvent.EventType` and `CGEventType`.
///
fileprivate let kCGEventLastUniversalType: CGEventType = .otherMouseDragged;
