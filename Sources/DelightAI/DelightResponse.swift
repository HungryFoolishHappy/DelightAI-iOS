//
//  DelightResponse.swift
//
//  Created by Delight team on 2/7/2024.
//

import Foundation

public struct DelightPollingResponse: Codable {
    public let uuid: String
    public let completed: Bool
    public let text: String?
    public let new_tokens: String?
}

public struct DelightRequest: Encodable {
    let message: Message
    
    struct Message: Encodable {
        let message_id: String
        let from: From
        let date: Int
        let text: String
        
        struct From: Encodable {
            let id: String
            let username: String
            let language_code: String
        }
    }
}

public struct DelightResponse: Codable {
    public let text: String
    public let shouldEndConversation: Bool
    public let poll: String
}

public struct ChatError: Codable {
    public struct Payload: Codable {
        public let message, type: String
        public let param, code: String?
    }
    
    public let error: Payload
}
