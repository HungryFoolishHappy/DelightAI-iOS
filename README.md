# DelightAI-iOS

## Installation 💻

### Add a package dependency

In your Xcode project, select File > Add Package Dependency and enter this repository URL: https://github.com/HungryFoolishHappy/DelightAI-iOS.git . 

## Demo

https://github.com/user-attachments/assets/3a015f71-3de5-418d-816d-8865226b4f97


## Usage Example

Import and init the framework in your project:

```swift
import DelightAI
let delightAI = DelightAI()
```

Call the sendChat function to send user text/prompt, then wait for agent response. Here is the async/await version.

```swift
do {
    let result = try await delight.sendChat(text: "Hello", // text to DelightAI, usually user’s message or prompt
                                        webhookId: "6b86705a-8b32-48d2-b176-ba518bb3d1e0", // our demo webhook id, or your agent’s actual webhook id from https://delight.global
                                        userId: "Wi-iOS-9937-491d-aefd-xxxxx",
                                        username: "Wi-iOS-9937-491d-aefd-xxxxx")
    // use result
} catch {
    // ...
}
```

Also supports the completion handler variant.

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
