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
}

class Card {
    let id: Int
    let emoji: String
    var state: CardState
    
    init(id: Int, emoji: String) {
        self.id = id
        self.emoji = emoji
        self.state = .faceDown
    }
    
    func flip() {
        switch state {
        case .faceDown:
            state = .faceUp
        case .faceUp:
            state = .faceDown
        case .matched:
            break
        }
    }
    
    func setMatched() {
        state = .matched
    }
}