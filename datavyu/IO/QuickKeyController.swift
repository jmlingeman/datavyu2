//
//  QuickKeyController.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/26/24.
//

import Combine
import Foundation
import SwiftUI

public typealias KeyInputSubject = PassthroughSubject<KeyEquivalent, Never>

public final class KeyInputSubjectWrapper: ObservableObject, Subject {
    public func send(_ value: Output) {
        objectWillChange.send(value)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        objectWillChange.send(completion: completion)
    }

    public func send(subscription: Subscription) {
        objectWillChange.send(subscription: subscription)
    }

    public typealias ObjectWillChangePublisher = KeyInputSubject
    public let objectWillChange: ObjectWillChangePublisher
    public init(subject: ObjectWillChangePublisher = .init()) {
        objectWillChange = subject
    }
}

// MARK: Publisher Conformance

public extension KeyInputSubjectWrapper {
    typealias Output = KeyInputSubject.Output
    typealias Failure = KeyInputSubject.Failure

    func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        objectWillChange.receive(subscriber: subscriber)
    }
}

public func keyboardShortcut<Sender, Label>(
    _ key: KeyEquivalent,
    sender: Sender,
    modifiers: EventModifiers = .none,
    @ViewBuilder label: () -> Label
) -> some View where Label: View, Sender: Subject, Sender.Output == KeyEquivalent {
    Button(action: { sender.send(key) }, label: label)
        .keyboardShortcut(key, modifiers: modifiers)
}

public func keyboardShortcut<Sender>(
    _ key: KeyEquivalent,
    sender: Sender,
    modifiers: EventModifiers = .none
) -> some View where Sender: Subject, Sender.Output == KeyEquivalent {
    let nameFromKey = key.character
    return AnyView(keyboardShortcut(key, sender: sender, modifiers: modifiers) {
        Text("\(nameFromKey)")
    })
}

extension KeyEquivalent {
    var lowerCaseName: String? {
        switch self {
        case .space: return "space"
        case .clear: return "clear"
        case .delete: return "delete"
        case .deleteForward: return "delete forward"
        case .downArrow: return "down arrow"
        case .end: return "end"
        case .escape: return "escape"
        case .home: return "home"
        case .leftArrow: return "left arrow"
        case .pageDown: return "page down"
        case .pageUp: return "page up"
        case .return: return "return"
        case .rightArrow: return "right arrow"
        case .space: return "space"
        case .tab: return "tab"
        case .upArrow: return "up arrow"
        default: return nil
        }
    }

    var name: String? {
        lowerCaseName?.capitalizingFirstLetter()
    }
}

public extension EventModifiers {
    static let none = Self()
}

extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }
}

extension KeyEquivalent: CustomStringConvertible {
    public var description: String {
        name ?? "\(character)"
    }
}
