# DelightAI-iOS

## Installation 💻

### Add a package dependency

Xcode project, select File > Add Package Dependency and enter its repository URL.

https://github.com/HungryFoolishHappy/DelightAI-iOS.git

## Usage Example

Import the framework in your project:

```swift
import DelightAI
let delightAI = DelightAI()
```

Support async/await

```swift
do {
    let result = try await delight.sendChat(text: "Hello", 
                                        webhookId: "6b86705a-8b32-48d2-b176-ba518bb3d1e0", // a demo webhook Id, you can use it for testing
                                        userId: "Wi-iOS-9937-491d-aefd-xxxxx",
                                        username: "Wi-iOS-9937-491d-aefd-xxxxx")
    // use result
} catch {
    // ...
}
```

Support completion handler variant.

```swift
do {
    delight.sendChat(text: text, 
                     webhookId: webhookId,
                     userId: userId,
                     username: username) { result in
        switch result {
        case.success(let success):
            print(success)
        case .failure(let failure):
            print(failure)
        }
        
    }
} catch {
    // ...
}
```
