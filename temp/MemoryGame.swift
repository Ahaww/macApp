//
//  MemoryGame.swift
//  temp
//
//  Created by F04 on 2025/11/20.
//

import Foundation

protocol MemoryGameDelegate: AnyObject {
    func didUpdateScore(score: Int)
    func didUpdateMoves(moves: Int)
    func didMatchCards()
    func didWinGame()
}

class MemoryGame {
    weak var delegate: MemoryGameDelegate?
    
    private var cards: [Card] = []
    private var selectedCards: [Card] = []
    private var isCheckingMatch = false
    
    var score: Int = 0
    var moves: Int = 0
    var isGameWon: Bool = false
    
    private let emojis = ["🎈", "🎨", "🎯", "🎪", "🎭", "🎸", "🎺", "🎲"]
    
    init() {
        setupGame()
    }
    
    private func setupGame() {
        cards.removeAll()
        selectedCards.removeAll()
        score = 0
        moves = 0
        isGameWon = false
        isCheckingMatch = false
        
        // 创建成对的卡片
        var cardId = 0
        for emoji in emojis {
            for _ in 0..<2 {
                let card = Card(id: cardId, emoji: emoji)
                cards.append(card)
                cardId += 1
            }
        }
        
        // 打乱卡片顺序
        cards.shuffle()
    }
    
    func getCards() -> [Card] {
        return cards
    }
    
    func selectCard(at index: Int) {
        guard !isGameWon, !isCheckingMatch else { return }
        
        let card = cards[index]
        
        // 如果卡片已经匹配或正面朝上，不能选择
        if card.state == .matched || card.state == .faceUp {
            return
        }
        
        // 翻开卡片
        card.flip()
        selectedCards.append(card)
        
        // 检查是否选择了两张卡片
        if selectedCards.count == 2 {
            moves += 1
            delegate?.didUpdateMoves(moves: moves)
            checkForMatch()
        }
    }
    
    private func checkForMatch() {
        isCheckingMatch = true
        
        let card1 = selectedCards[0]
        let card2 = selectedCards[1]
        
        if card1.emoji == card2.emoji {
            // 匹配成功
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                card1.setMatched()
                card2.setMatched()
                self.score += 10
                self.delegate?.didUpdateScore(score: self.score)
                self.delegate?.didMatchCards()
                self.selectedCards.removeAll()
                self.isCheckingMatch = false
                
                // 检查是否获胜
                if self.checkWinCondition() {
                    self.isGameWon = true
                    self.delegate?.didWinGame()
                }
            }
        } else {
            // 匹配失败
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                card1.flip()
                card2.flip()
                self.selectedCards.removeAll()
                self.isCheckingMatch = false
            }
        }
    }
    
    private func checkWinCondition() -> Bool {
        return cards.allSatisfy { $0.state == .matched }
    }
    
    func resetGame() {
        setupGame()
        delegate?.didUpdateScore(score: score)
        delegate?.didUpdateMoves(moves: moves)
    }
}