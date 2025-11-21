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
    private var unmatchedFaceUpCards: [Card] = []
    private var faceUpTimers: [Int: Timer] = [:] // 存储卡片ID和对应的计时器
    
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
        unmatchedFaceUpCards.removeAll()
        invalidateAllTimers()
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
        
        // 如果卡片已经匹配或正在检查中，不能选择
        if card.state == .matched || card.state == .disappeared || isCheckingMatch {
            return
        }
        
        // 取消该卡片可能存在的计时器
        if let timer = faceUpTimers[card.id] {
            timer.invalidate()
            faceUpTimers[card.id] = nil
        }
        
        // 如果卡片已经正面朝上，不做任何操作
        if card.state == .faceUp {
            return
        }
        
        // 每次点击卡片（且卡片未正面朝上）时增加步数
        moves += 1
        delegate?.didUpdateMoves(moves: moves)
        
        // 翻开卡片
        card.flip()
        
        // 先将卡片添加到未匹配正面朝上的卡片列表
        unmatchedFaceUpCards.append(card)
        
        // 立即检查是否有已经正面朝上且未匹配的卡片可以与当前卡片匹配
        checkForMatchingFaceUpCards()
        
        // 如果卡片仍然是正面朝上且未匹配状态，设置自动翻回计时器
        if card.state == .faceUp {
            setupAutoFlipTimer(for: card)
        }
    }
    
    // 检查是否有已经正面朝上且未匹配的卡片可以相互匹配
    private func checkForMatchingFaceUpCards() {
        // 首先清理unmatchedFaceUpCards中的无效卡片（已匹配或已消失的卡片）
        unmatchedFaceUpCards = unmatchedFaceUpCards.filter { $0.state == .faceUp }
        
        // 如果没有足够的卡片进行匹配，直接返回
        if unmatchedFaceUpCards.count < 2 {
            return
        }
        
        // 找出所有匹配的卡片对
        var matchedPairs: [(Card, Card)] = []
        var processedCardIds: Set<Int> = []
        
        // 遍历所有可能的卡片对，找出匹配的卡片
        for i in 0..<unmatchedFaceUpCards.count {
            if processedCardIds.contains(unmatchedFaceUpCards[i].id) {
                continue
            }
            
            for j in i+1..<unmatchedFaceUpCards.count {
                if processedCardIds.contains(unmatchedFaceUpCards[j].id) {
                    continue
                }
                
                let card1 = unmatchedFaceUpCards[i]
                let card2 = unmatchedFaceUpCards[j]
                
                // 如果发现两张emoji相同但ID不同的卡片
                if card1.emoji == card2.emoji && card1.id != card2.id {
                    matchedPairs.append((card1, card2))
                    processedCardIds.insert(card1.id)
                    processedCardIds.insert(card2.id)
                    break // 一张卡片只能匹配一次
                }
            }
        }
        
        // 如果有匹配的卡片对，处理匹配逻辑
        if !matchedPairs.isEmpty {
            isCheckingMatch = true
            // 步数已经在selectCard方法中增加，这里不再重复计算
            
            // 取消所有匹配卡片的计时器
            for (card1, card2) in matchedPairs {
                if let timer = faceUpTimers[card1.id] {
                    timer.invalidate()
                    faceUpTimers[card1.id] = nil
                }
                if let timer = faceUpTimers[card2.id] {
                    timer.invalidate()
                    faceUpTimers[card2.id] = nil
                }
            }
            
            // 匹配成功，等待一小段时间后将卡片标记为消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                var isAnyMatchSuccessful = false
                
                // 处理每对匹配的卡片
                for (card1, card2) in matchedPairs {
                    // 再次检查卡片状态，确保在延迟期间没有被其他操作改变
                    if card1.state == .faceUp && card2.state == .faceUp {
                        card1.setMatched()
                        card2.setMatched()
                        self.score += 10
                        isAnyMatchSuccessful = true
                    }
                    
                    // 清理unmatchedFaceUpCards中的这些卡片
                    self.unmatchedFaceUpCards.removeAll(where: { $0.id == card1.id || $0.id == card2.id })
                }
                
                // 如果有任何匹配成功，更新分数和通知代理
                if isAnyMatchSuccessful {
                    self.delegate?.didUpdateScore(score: self.score)
                    self.delegate?.didMatchCards()
                }
                
                self.isCheckingMatch = false
                
                // 检查是否获胜
                if self.checkWinCondition() {
                    self.isGameWon = true
                    self.delegate?.didWinGame()
                }
            }
        }
    }
    
    // 为卡片设置1秒后自动翻回的计时器
    private func setupAutoFlipTimer(for card: Card) {
        // 确保不会为同一张卡片设置多个计时器
        if let existingTimer = faceUpTimers[card.id] {
            existingTimer.invalidate()
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // 移除计时器引用
            self.faceUpTimers[card.id] = nil
            
            // 确保卡片仍然是正面朝上且未匹配状态
            if card.state == .faceUp {
                DispatchQueue.main.async {
                    // 只有在没有正在检查匹配时才翻回
                    if !self.isCheckingMatch {
                        card.flip()
                        // 从列表中移除
                        self.unmatchedFaceUpCards.removeAll(where: { $0.id == card.id })
                        
                        // 我们需要一种方式来通知ViewController更新视图，但不触发匹配成功的效果
                        // 最简单的解决方案是在MemoryGameDelegate中添加一个新的方法
                        // 但为了保持最小修改，我们可以通过didUpdateMoves间接触发视图更新
                        // 因为ViewController在didUpdateMoves中可能会更新UI状态
                        self.delegate?.didUpdateMoves(moves: self.moves)
                    }
                }
            }
        }
        
        faceUpTimers[card.id] = timer
        // 将计时器添加到当前运行循环中
        RunLoop.current.add(timer, forMode: .common)
    }
    
    // 清理所有计时器
    private func invalidateAllTimers() {
        for (_, timer) in faceUpTimers {
            timer.invalidate()
        }
        faceUpTimers.removeAll()
    }
    
    private func checkWinCondition() -> Bool {
        // 检查所有卡片是否都已匹配（包括disappeared状态）
        return cards.allSatisfy { $0.state == .matched || $0.state == .disappeared }
    }
    
    func resetGame() {
        setupGame()
        delegate?.didUpdateScore(score: score)
        delegate?.didUpdateMoves(moves: moves)
    }
    
    // 析构函数，确保在对象销毁时清理计时器
    deinit {
        invalidateAllTimers()
    }
}