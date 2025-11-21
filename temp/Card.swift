//
//  Card.swift
//  temp
//
//  Created by F04 on 2025/11/20.
//

import Foundation

enum CardState {
    case faceDown
    case faceUp
    case matched
    case disappeared
}

class Card: Equatable {
    let id: Int
    let emoji: String
    var state: CardState
    
    init(id: Int, emoji: String) {
        self.id = id
        self.emoji = emoji
        self.state = .faceDown
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.id == rhs.id
    }
    
    func flip() {
        switch state {
        case .faceDown:
            state = .faceUp
        case .faceUp:
            state = .faceDown
        case .matched, .disappeared:
            break
        }
    }
    
    func setMatched() {
        state = .disappeared
    }
}