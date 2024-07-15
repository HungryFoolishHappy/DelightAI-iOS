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
    /// Send a Chat request to the Delight API
    /// - Parameters
    ///     - text: textual message
    ///     - webhookId: specific Id of the agent
    ///     - userId: sender Id
    ///     - username: sender name
    ///     - completionHandler: Returns a DelightResponse
    public func sendChat(text: String,
                          webhookId: String,
                          userId: String,
                          username: String,
                          messageId: String? = nil,
                          completionHandler: @escaping (Result<DelightResponse, DelightAIError>) -> Void) {
        guard let url = URL(string: "\(self.config.baseURL)/webhook/webwidget/\(webhookId)/") else {
            return completionHandler(.failure(.invalidURL))
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let timestamp = Int(NSDate().timeIntervalSince1970 * 1000)
        
        let body = DelightRequest(
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
        
        if let encoded = try? JSONEncoder().encode(body) {
            request.httpBody = encoded
        }
        
        makeRequest(request: request) { result in
            switch result {
            case .success(let success):
                if let chatErr = try? JSONDecoder().decode(ChatError.self, from: success) as ChatError {
                    completionHandler(.failure(.chatError(error: chatErr.error)))
                    return
                }
                
                do {
                    let res = try JSONDecoder().decode(DelightResponse.self, from: success)
                    completionHandler(.success(res))
                } catch {
                    completionHandler(.failure(.decodingError(error)))
                }
                
            case .failure(let failure):
                completionHandler(.failure(.requestError(failure)))
            }
            
        }
    }
    
    /// send polling request to the Delight API
    /// - Parameters:
    ///     - pollingUrl: polling URL for requests to the Delight API
    ///     - completionHandler: Returns a DelightPollingResponse
    public func polling(pollingUrl: String,
                 completionHandler: @escaping (Result<DelightPollingResponse, DelightAIError>) -> Void) {
        guard let url = URL(string: self.config.baseURL + pollingUrl) else {
            return completionHandler(.failure(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        
        makeRequest(request: request) { result in
            switch result {
            case .success(let success):
                do {
                    let res = try JSONDecoder().decode(DelightPollingResponse.self, from: success)
                    completionHandler(.success(res))
                } catch {
                    completionHandler(.failure(.decodingError(error)))
                }
            case .failure(let failure):
                completionHandler(.failure(.requestError(failure)))
            }
        }
    }
    
    private func makeRequest(request: URLRequest, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        let session = config.session
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data {
                completionHandler(.success(data))
            }
        }
        
        task.resume()
    }
}

extension DelightAI {
    /// Send a Chat request to the Delight API
    /// - Parameters
    ///     - text: textual message
    ///     - webhookId: specific Id of the agent
    ///     - userId: sender Id
    ///     - username: sender name
    /// - Returns: Returns a DelightResponse
    @available(swift 5.5)
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    public func sendChat(text: String,
                          webhookId: String,
                          userId: String,
                          username: String,
                          messageId: String? = nil) async throws -> DelightResponse {
        return try await withCheckedThrowingContinuation { continuation in
            sendChat(text: text, webhookId: webhookId, userId: userId, username: username) { result in
                        continuation.resume(with: result)
                    }
                }
    }
    
    /// send polling request to the Delight API
    /// - Parameters:
    ///     - pollingUrl: polling URL for requests to the Delight API
    /// - Returns: Returns a DelightPollingResponse
    @available(swift 5.5)
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    public func polling(pollingUrl: String) async throws -> DelightPollingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            polling(pollingUrl: pollingUrl) { result in
                        continuation.resume(with: result)
                    }
                }
    }
}

