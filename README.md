### Features

- The AlertFactory generic type Alert doesn't need to be a UIViewController any more, but, if it is not, you should write the `alertController: UIViewController { get }`.
- Added a handler for layout `applyLayout`before presenting the alertController.
- You can override `AlertFactory` for standards error alerts using `AlertFactoryError`.
- `defaultCancelTitle` and `defaultForceCancelTitle` are properties in `AlertFactory` used to display default cancels buttons on alert.

# AlertFactory

[![CI Status](https://img.shields.io/travis/umobi/AlertFactory.svg?style=flat)](https://travis-ci.org/umobi/AlertFactory)
[![Version](https://img.shields.io/cocoapods/v/AlertFactory.svg?style=flat)](https://cocoapods.org/pods/AlertFactory)
[![License](https://img.shields.io/cocoapods/l/AlertFactory.svg?style=flat)](https://cocoapods.org/pods/AlertFactory)
[![Platform](https://img.shields.io/cocoapods/p/AlertFactory.svg?style=flat)](https://cocoapods.org/pods/AlertFactory)

## Installation

AlertFactory is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AlertFactory'
```

### Definitions

----

#### 1. AlertFactory
AlertFactory is the main core that needs to be specified the Alert generic type as **AlertFactoryType**.

The library already has implemented the extension for UIAlertController, so you can use the AlertFactory without writing any code, just calling `AlertFactory<UIAlertController>`.

The methods to create the alert are:

- .init(viewController: **UIViewController?**)
- .with(title: Title)
- .with(text: Text)
- .append(text: Text.Element) where Text == Array
- .with(image: UIImage)
- .otherButton(title: String, onTap: (() -> Void)?=nil)
- .cancelButton(title: String, onTap: (() -> Void)?=nil)
- .destructiveButton(title: String, onTap: (() -> Void)? = nil)
- .forError(_ error: **AlertFactoryError**)
- .onDismiss( _ completion: (() -> Void)?)
- .present(completion: (() -> Void)? = nil)
- .append()
- .asAlertView() -> UIViewController?
- .applyLayout(_ handler: (Alert) -> Void))

The specifications for otherButton, cancelButton and destructiveButton are for UIAlertController button types.

The append() method should be used to discard the AlertFactory self-return.

#### 2. AlertFactoryType

The AlertFactoryType is a protocol that helps AlertFactory to delivery the payload that it has mounted to the AlertController provider. Here, you can integrate any UIViewController with AlertFactory.

So, the methods are similar to the methods used to create the alert:
##### func with(title: Title) -> Self
The Title type is a generic type that allows you to create different layouts for your alert depending on what you want to do. It can be any class, struct, enum, and primitive types. It is all ready for you to use. You only need to specify the type when you write the extension of AlertFactory in function parameter because it is an associated type. <b>(Added in version 1.1.0)</b>

Depending on the AlertController, you will have to recreate the AlertController or just call some method like .setTitle(title)

The example for UIAlertController already done in this library is:
```swift
extension UIAlertController: AlertFactoryType {
    public func with(title: String) -> Self {
        return .init(title: title, message: self.message, preferredStyle: self.preferredStyle)
    }
}
```
##### func with(text: Text) -> Self
As same as with(title:), we rewrite this function to use associated type, which allows you to write more complex alerts. So, if your parameter is an Array, automatically, you will have to functions in AlertFactory, the default one is .with(text: [Element]) and the second one is .append(text: Element). Now, you do not need to specify an index, only appending in the write order.

```swift
// Text as primitive type
extension UIAlertController: AlertFactoryType {
    public func with(text: String) -> Self {
        return .init(title: self.title, message: text, preferredStyle: self.preferredStyle)
    }
}
```

```
// Text as Array of primitive
extension AlertController: AlertFactoryType {
    public func with(text: [String]) -> Self {
        text.forEach {
            self.subtitle.append($0)
        }
        return self
     }
}
```

##### func with(image: UIImage) -> Self
This method is optional but will be called everything you use AlertFactory.with(image:). As it means, you can set an image to your alert if is available.

```swift
extension ExampleAlertController: AlertFactoryType {
    func with(image: UIImage) -> Self {
        self.setImage(image)
        return self
    }
}
```

##### func append(button: AlertFactoryButton) -> Self

The AlertFactoryButton is a wrapper created by AlertFactory and holds the pieces of information necessary to create the action button. But, depending on your AlertController, the style property doesn't fit well. So, you should implement some adaptions to this.

The default UIAlertController example:
```swift
extension UIAlertController: AlertFactoryType {
    public func append(button: AlertFactoryButton) -> Self {
        let action = UIAlertAction(title: button.title, style: button.style, handler: { _ in
            button.onTap?()
        })

        self.addAction(action)

        if button.isPreferred {
            if #available(iOS 9.0, *) {
                self.preferredAction = action
            }
        }

        return self
    }
}
```

We have implemented the same method for [MDCAlertController](https://github.com/material-components/material-components-ios "MDCAlertController") in your other projects to use Dialogs from MaterialComponents.
```swift
extension MDCAlertController: AlertFactoryType {
    public func append(button: AlertFactoryButton) -> Self {
        let emphasis: MDCActionEmphasis = {
            switch button.style {
            case .default:
                return .medium
            case .destructive:
                return .high
            case .cancel:
                return .medium
            @unknown default:
                return .medium
            }
        }()

        self.addAction(MDCAlertAction(title: button.title, emphasis: emphasis, handler:  { _ in
            button.onTap?()
        }))

        return self
    }
}
```

##### Other methods

You can implement the methods `with(preferredStyle: UIAlertController.Style)`, `append(textField: AlertFactoryField)` and `didConfiguredAlertView()`. 

The `didConfiguredAlertView()` is important to stylize your AlertController without implementing a default class and use it as your alert.

#### 3. AlertFactoryError
A new implementation for this is using the Title and Text generic types, so, your AlertFactoryError should constraint the same type as specified in the AlertFactoryType.

We move the .forError() rules to inside AlertFactoryError, the only thing you need is to specify correctly the title and text types.

The first step we did is to implement the `.forError(_ error: Swift.Error) -> Self {}` in your BaseAlertFactory.  Because we want to override the AlertFactoryError.

```swift
import AlertFactory

class BaseAlertFactory<Alert: UIViewController & AlertFactoryType>: AlertFactory<Alert> {
    func forError(_ error: Swift.Error) -> Self {
        if error.isSessionExpired {
            self.destructiveButton(title: "Login", onTap: {
                User.login()
                AppDelegate.shared.changeToLoginView()
            }).append()
        }
        
        // Where we pass the overriden AlertFactoryError
        super.forError(BaseAlertFactoryError(error)).append()
        return self
    }
```

```swift 
import AlertFactory
class BaseAlertFactoryError: AlertFactoryErrorType {

    var text: String? {
        if self.error.isSessionExpired {
            return "To continue using this app do the login again."
        }

        return self.error.localizedDescription
    }

    var title: String? {
        return nil
    }

    public let error: Swift.Error

    required public init(_ error: Swift.Error) {
        self.error = error
    }
}
```
This is a simple example, but you can create classes extended with AlertFactoryError and override the title and text parameters and use it by implementing your BaseAlertFactory like the example above.

### Usage
---
Now, you are able to start using AlertFactory by reading the **Definitions**. So, this project has an [example](https://github.com/umobi/AlertFactory/blob/master/Example/AlertFactory/ViewController.swift "example") to guide you using this library.

We have different situations to construct some alerts and we will specify the ones that we used in our projects.

#### 1. Creating a Simple Alert

```swift
import AlertFactory

class MainViewController: UIViewController {
    // ... MainViewController settings

    @IBAction func showHelloWorldAlert(_ sender: UIButton!) {
        AlertFactory<UIAlertController>(viewController: self)
            .with(title: "Hello World!")
            .with(text: "Implementing my first alert using AlertFactory")
            .cancelButton(title: "Dismiss")
            .present()
    }
}
```

#### 2. Treating Error Actions
We have FieldValidationError as Error class child, we want to call the correct Field after the AlertController be dismissed using the **BaseAlertFactory** example.
```swift
import AlertFactory

class MainViewController: UIViewController {
    // ... MainViewController settings

    func showFieldValidationError(_ fieldError: FieldValidationError) {
        BaseAlertFactory<UIAlertController>(viewController: self)
            .forError(fieldError)
            .onDismiss { [weak self] in
                switch fieldError.field {
                case .cep:
                    _ = self?.cepField.becomeFirstResponder()
                case .neighborhood:
                    _ = self?.neighborhoodField.becomeFirstResponder()
                default:
                    break
                }
            }.present()
    }
}
```
#### 3. Different Buttons for some Event
This helps when you are creating the .actionSheet and you want to display or not the delete photo just if the user had selected some photo before. You can do this by calling the .append() method.

```swift
import AlertFactory

extension MainViewController {
    func presentPickerOptions() {
        let alert = AlertFactory<UIAlertController>(viewController: self)
            .with(preferredStyle: .actionSheet)
            .with(title: "Profile")
            .with(text: "Pick your profile image")
            .cancelButton()
            .otherButton(title: "Photo Library") { [weak self] in
                self?.openImagePickerController(sourceType: .photoLibrary)
            }.otherButton(title: "Camera") { [weak self] in
                self?.openImagePickerController(sourceType: .camera)
            }

        if self.profileImage {
            alert.destructiveButton(title: "Delete Photo") { [weak self] in
                self?.deletePhoto()
            }.append()
        }

        alert.present()
    }
}
```

#### 4. Passing the AlertController as UIViewController
Sometimes, we can use other classes to present the AlertController and maybe it does not have the UIViewController.present(). With this, you can call .asAlertView() to create your AlertController using AlertFactory.

```swift
import AlertFactory

class Event {
    func onEvent(_ event: EventPayload) {
        let alertController = AlertFactory<UIAlertController>()
            .with(title: event.title)
            .with(text: event.message)
            .cancelButton() {
                self.userDidCancel(event)
            }.otherButton(title: "Accept") {
                self.userDidAccept(event)
            }.asAlertView()

        self.present(alertController)
    }
}
```

#### 5. Hidden `Alert` generic type

To make your code easier to read you can create a class that extends AlertFactory and call it without specifying the Alert parameter all the time.

```swift
import AlertFactory

class UIAlertFactory: AlertFactory<UIAlertController> {}
```

```swift
extension MainViewController {
    func presentAlert() {
        UIAlertFactory(viewController: self)
            .with(title: "Hello World")
            .present()
    }
}
```

## Author

brennobemoura, brennobemoura@outlook.com.br

## License

AlertFactory is available under the MIT license. See the LICENSE file for more info.

### End
