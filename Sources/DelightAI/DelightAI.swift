import Foundation
#if canImport(FoundationNetworking) && canImport(FoundationXML)
import FoundationNetworking
import FoundationXML
#endif

public enum DelightAIError: Error {
    case invalidURL
    case requestError(_ error: Error)
    case decodingError(_ error: Error)
    case chatError(error: ChatError.Payload)
    case attemptMore
    case unsupportedVersion
    
    public var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .requestError(let error): return "Request error: \(error.localizedDescription)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .attemptMore: return "Error. Please try later"
        case .chatError: return  "Error. Please try later"
        case .unsupportedVersion: return "Error. Unsupported System Version"
        }
    }
}

public class DelightAI {
    fileprivate let config: Config
    
    /// Configuration object for the client
    public struct Config {
        
        public init(baseURL: String, session: URLSession) {
            self.baseURL = baseURL
            self.session = session
        }
        let baseURL: String
        let session: URLSession
        
        public static func makeDefaultDelightAI() -> Self {
            .init(baseURL: "https://qa.delight.global", session: .shared)
        }
    }
    
    public init(config: Config) {
        self.config = config
    }
    
    public init() {
        self.config = .makeDefaultDelightAI()
    }
}

extension DelightAI {
    /// send a Chat request to the Delight API and integrate sending and polling into one function.
    /// - Parameteres:
    ///     - text: textual message
    ///     - webhookId: specific Id of the agent
    public func sendChat(text: String, webhookId: String, userId: String, username: String, messageId: String? = nil) async -> Result<DelightPollingResponse, DelightAIError> {
        let result = await send(text: text, webhookId: webhookId, userId: userId, username: username, messageId: messageId)
        let attemptCount = 30
        switch result {
        case .success(let success):
            let resultPolling = await polling(pollingUrl: self.config.baseURL + success.poll, attempt: attemptCount)
            switch resultPolling {
                case .success(let pollingRepsonse):
                    return .success(pollingRepsonse)
                case .failure(let error):
                    return .failure(error)
            }
        case .failure(let error):
            return .failure(.requestError(error))
        }
    }
    
    /// Send a Chat request to the Delight API
    /// - Parameters
    ///     - text: textual message
    ///     - webhookId: specific Id of the agent
    private func send(text: String, webhookId: String, userId: String, username: String, messageId: String?) async -> Result<DelightResponse, DelightAIError> {
        guard let url = URL(string: "\(self.config.baseURL)/webhook/webwidget/\(webhookId)/") else {
            return .failure(.invalidURL)
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let timestamp = Int(NSDate().timeIntervalSince1970 * 1000)
    
        let message = DelightRequest(
            message: DelightRequest.Message(
                message_id: messageId ?? "Wi-iOS-" + UUID().uuidString,
                from: DelightRequest.Message.From(
                    id: userId,
                    username: username,
                    language_code: "en"
                ),
                date: timestamp,
                text: text
            )
        )
        
        do {
            let delightRequest = try! JSONEncoder().encode(message)
            request.httpBody = delightRequest
            let (data, U) = try await URLSession.shared.data(for: request)
            let activity = try JSONDecoder().decode(DelightResponse.self, from: data)
            return .success(activity)
        } catch let error {
            return .failure(.requestError(error))
        }
    }
    
    /// send polling request to the Delight API
    /// - Parameters:
    ///     - pollingUrl: polling URL for requests to the Delight API
    ///     - attempt: the number of retries for polling requests to the Delight API
    private func polling(pollingUrl: String, attempt: Int = 60) async -> Result<DelightPollingResponse, DelightAIError> {
        if (attempt == 0) {
            return .failure(DelightAIError.attemptMore)
        }
        guard let url = URL(string: pollingUrl) else {
            return .failure(.invalidURL)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let response = try JSONDecoder().decode(DelightPollingResponse.self, from: data)

            if (response.completed) {
                return .success(response)
            }
            // wait for 1 second for each request
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return await polling(pollingUrl: pollingUrl, attempt: attempt - 1)
        } catch let error {
            return .failure(.requestError(error))
        }
    }
}
