//
// Copyright (c) 2019-Present Umobi - https://github.com/umobi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import SwiftUI

public struct SUIAlert: RawAlert {
    typealias ButtonPayload = (TextContent, ButtonStyle, () -> Void)

    private let title: TextContent?
    private let message: TextContent?
    private let buttons: [ButtonPayload]

    public init() {
        self.title = nil
        self.message = nil
        self.buttons = []
    }

    private init(_ original: SUIAlert, editable: Editable) {
        self.title = editable.title
        self.message = editable.message
        self.buttons = editable.buttons.unique().sorted(by: { $0.1 < $1.1 })
    }

    private func edit(_ edit: @escaping (Editable) -> Void) -> Self {
        let editable = Editable(self)
        edit(editable)
        return .init(self, editable: editable)
    }

    private func button(title: TextContent, style: ButtonStyle, onTap: @escaping () -> Void) -> Self {
        self.edit {
            $0.buttons.append((title, style, onTap))
        }
    }

    private class Editable {
        var title: TextContent?
        var message: TextContent?
        var buttons: [(TextContent, ButtonStyle, () -> Void)]

        init(_ original: SUIAlert) {
            self.title = original.title
            self.message = original.message
            self.buttons = original.buttons
        }
    }

    private func makePrimaryButton(_ isPresenting: Binding<Bool>) -> Alert.Button {
        guard let primary = self.buttons.reversed().last else {
            fatalError()
        }

        return Self.unwrappButton(primary, isPresenting)
    }

    private func makeSecondaryButton(_ isPresenting: Binding<Bool>) -> Alert.Button {
        guard let secondary = self.buttons.reversed().dropLast().last else {
            fatalError()
        }

        return Self.unwrappButton(secondary, isPresenting)
    }

    private func alertMaker(_ isPresenting: Binding<Bool>) -> Alert {
        if self.buttons.isEmpty {
            return Alert(
                title: Self.makeTitle(self.title),
                message: Self.makeMessage(self.message),
                dismissButton: nil
            )
        }

        if self.buttons.count == 1 {
            return Alert(
                title: Self.makeTitle(self.title),
                message: Self.makeMessage(self.message),
                dismissButton: self.makePrimaryButton(isPresenting)
            )
        }

        return Alert(
            title: Self.makeTitle(self.title),
            message: Self.makeMessage(self.message),
            primaryButton: self.makePrimaryButton(isPresenting),
            secondaryButton: self.makeSecondaryButton(isPresenting)
        )
    }

    public func render<Content: View>(_ content: Content, _ isPresenting: Binding<Bool>) -> AnyView {
        AnyView(content.alert(isPresented: isPresenting, content: { self.alertMaker(isPresenting) }))
    }
}

public extension SUIAlert {

    enum TextContent {
        case string(String)
        case text(Text)
    }

    enum ButtonStyle: Comparable {
        case cancel
        case `default`
        case destructive

        public static func <(_ lhs: ButtonStyle, _ rhs: ButtonStyle) -> Bool {
            switch lhs {
            case .cancel:
                return false

            case .default:
                if case .destructive = rhs {
                    return true
                }
                return false
            case .destructive:
                if case .destructive = rhs {
                    return false
                }

                return true
            }
        }
    }
}

public extension SUIAlert {

    func title(_ title: String) -> Self {
        self.edit {
            $0.title = .string(title)
        }
    }

    func title(_ text: Text) -> Self {
        self.edit {
            $0.title = .text(text)
        }
    }
}

public extension SUIAlert {

    func message(_ message: String) -> Self {
        self.edit {
            $0.message = .string(message)
        }
    }

    func message(_ text: Text) -> Self {
        self.edit {
            $0.message = .text(text)
        }
    }
}

public extension SUIAlert {

    func cancelButton(title: String, onTap: @escaping () -> Void) -> Self {
        self.button(
            title: .string(title),
            style: .cancel,
            onTap: onTap
        )
    }

    func cancelButton(title: String) -> Self {
        self.button(
            title: .string(title),
            style: .cancel,
            onTap: {}
        )
    }

    func cancelButton(title: Text, onTap: @escaping () -> Void) -> Self {
        self.button(
            title: .text(title),
            style: .cancel,
            onTap: onTap
        )
    }

    func cancelButton(title: Text) -> Self {
        self.button(
            title: .text(title),
            style: .cancel,
            onTap: {}
        )
    }
}

public extension SUIAlert {

    func defaultButton(title: String, onTap: @escaping () -> Void) -> Self {
        self.button(
            title: .string(title),
            style: .default,
            onTap: onTap
        )
    }

    func defaultButton(title: Text, onTap: @escaping () -> Void) -> Self {
        self.button(
            title: .text(title),
            style: .default,
            onTap: onTap
        )
    }
}

public extension SUIAlert {

    func destructiveButton(title: String, onTap: @escaping () -> Void) -> Self {
        self.button(
            title: .string(title),
            style: .destructive,
            onTap: onTap
        )
    }

    func destructiveButton(title: Text, onTap: @escaping () -> Void) -> Self {
        self.button(
            title: .text(title),
            style: .destructive,
            onTap: onTap
        )
    }
}

private extension SUIAlert {
    static func makeTitle(_ textContent: TextContent?) -> Text {
        switch textContent {
        case .string(let string):
            return Text(string)
                .font(.body)
                .foregroundColor(.black)
                .bold()

        case .text(let text):
            return text

        case .none:
            return Text("")
                .font(.body)
                .foregroundColor(.black)
                .bold()
        }
    }

    static func makeMessage(_ textContent: TextContent?) -> Text? {
        switch textContent {
        case .string(let string):
            return Text(string)
                .font(.callout)
                .foregroundColor(.black)
                .bold()

        case .text(let text):
            return text

        case .none:
            return nil
        }
    }

    static func unwrappButton(_ tuple: (TextContent, ButtonStyle, () -> Void), _ isPresenting: Binding<Bool>) -> Alert.Button {
        switch tuple.1 {
        case .cancel:
            return .cancel({
                switch tuple.0 {
                case .string(let string):
                    return Text(string)
                        .font(.body)
                        .bold()
                case .text(let text):
                    return text
                }
            }(), action: {
                tuple.2()
                isPresenting.wrappedValue = false
            })
        case .default:
            return .default({
                switch tuple.0 {
                case .string(let string):
                    return Text(string)
                        .font(.body)
                        .bold()
                case .text(let text):
                    return text
                }
            }(), action: {
                tuple.2()
                isPresenting.wrappedValue = false
            })
        case .destructive:
            return .destructive({
                switch tuple.0 {
                case .string(let string):
                    return Text(string)
                        .font(.body)
                        .bold()
                case .text(let text):
                    return text
                }
            }(), action: {
                tuple.2()
                isPresenting.wrappedValue = false
            })
        }
    }
}

extension Array where Element == SUIAlert.ButtonPayload {
    func unique() -> [Element] {
        var buttons = [Element]()

        for slice in self.reversed() {
            guard !buttons.contains(where: { $0.1 == slice.1 }) else {
                continue
            }

            buttons.append(slice)
        }

        return buttons
    }
}