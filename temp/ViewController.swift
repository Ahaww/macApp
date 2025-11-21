//
//  ViewController.swift
//  temp
//
//  Created by F04 on 2025/11/20.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController {
    
    private var memoryGame: MemoryGame!
    private var cardViews: [CardView] = []
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "得分: 0"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let movesLabel: UILabel = {
        let label = UILabel()
        label.text = "步数: 0"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重新开始", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let cardsContainerView: UIView = {
        let view = UIView()
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGame()
        setupUI()
    }
    
    private func setupGame() {
        memoryGame = MemoryGame()
        memoryGame.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // 设置标题
        title = "记忆翻牌游戏"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 添加子视图
        view.addSubview(scoreLabel)
        view.addSubview(movesLabel)
        view.addSubview(resetButton)
        view.addSubview(cardsContainerView)
        
        // 设置按钮动作
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        setupConstraints()
        setupCards()
    }
    
    private func setupConstraints() {
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        movesLabel.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        cardsContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scoreLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            
            movesLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            movesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            movesLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            
            resetButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            resetButton.heightAnchor.constraint(equalToConstant: 40),
            
            cardsContainerView.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 20),
            cardsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupCards() {
        // 清除旧的卡片视图
        cardViews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()
        
        let cards = memoryGame.getCards()
        let columns = 4
        let rows = 4
        let spacing: CGFloat = 12
        
        // 计算可用空间
        let containerWidth = cardsContainerView.frame.width > 0 ? cardsContainerView.frame.width : UIScreen.main.bounds.width - 40
        let containerHeight = cardsContainerView.frame.height > 0 ? cardsContainerView.frame.height : UIScreen.main.bounds.height - 200
        
        // 计算卡片尺寸
        let maxCardWidth = (containerWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let maxCardHeight = (containerHeight - spacing * CGFloat(rows - 1)) / CGFloat(rows)
        let cardSize = min(maxCardWidth, maxCardHeight, 80) // 限制最大尺寸为80
        
        // 计算起始位置以居中显示
        let totalWidth = cardSize * CGFloat(columns) + spacing * CGFloat(columns - 1)
        let totalHeight = cardSize * CGFloat(rows) + spacing * CGFloat(rows - 1)
        let startX = (containerWidth - totalWidth) / 2
        let startY = (containerHeight - totalHeight) / 2
        
        for (index, card) in cards.enumerated() {
            let cardView = CardView(card: card)
            cardView.translatesAutoresizingMaskIntoConstraints = false
            
            let row = index / columns
            let column = index % columns
            
            cardsContainerView.addSubview(cardView)
            
            NSLayoutConstraint.activate([
                cardView.widthAnchor.constraint(equalToConstant: cardSize),
                cardView.heightAnchor.constraint(equalToConstant: cardSize),
                cardView.topAnchor.constraint(equalTo: cardsContainerView.topAnchor, constant: startY + CGFloat(row) * (cardSize + spacing)),
                cardView.leadingAnchor.constraint(equalTo: cardsContainerView.leadingAnchor, constant: startX + CGFloat(column) * (cardSize + spacing))
            ])
            
            cardView.onTap = { [weak self] in
                self?.cardTapped(at: index)
            }
            
            cardViews.append(cardView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if cardViews.isEmpty {
            setupCards()
        }
    }
    
    @objc private func resetButtonTapped() {
        memoryGame.resetGame()
        setupCards()
    }
    
    private func cardTapped(at index: Int) {
        memoryGame.selectCard(at: index)
        
        // 更新被点击的卡片视图状态
        let cardView = cardViews[index]
        cardView.flipWithAnimation()
        
        // 在每次点击后立即更新所有卡片视图状态，确保匹配的卡片能够立即消失
        updateAllCardViews()
    }
    
    // 更新所有卡片视图状态
    private func updateAllCardViews() {
        let cards = memoryGame.getCards()
        for (index, cardView) in cardViews.enumerated() {
            // 确保索引有效
            if index < cards.count {
                // 无论卡片状态如何，都更新视图状态
                cardView.updateCardState()
            }
        }
    }
    
    private func showWinAlert() {
        let alert = UIAlertController(title: "恭喜获胜！", 
                                    message: "你用了 \(memoryGame.moves) 步完成了游戏！\n得分: \(memoryGame.score)", 
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "重新开始", style: .default) { _ in
            self.resetButtonTapped()
        })
        
        present(alert, animated: true)
    }
}

extension ViewController: MemoryGameDelegate {
    func didUpdateScore(score: Int) {
        scoreLabel.text = "得分: \(score)"
    }
    
    func didUpdateMoves(moves: Int) {
        movesLabel.text = "步数: \(moves)"
        // 更新所有卡片视图状态，确保自动翻回的卡片正确显示
        updateAllCardViews()
    }
    
    func didMatchCards() {
        // 更新所有卡片视图状态，特别是匹配成功要消失的卡片
        updateAllCardViews()
        
        // 添加震动反馈
        AudioServicesPlaySystemSound(1519) // 系统成功音效
        
        // 添加屏幕闪烁效果
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
        flashView.alpha = 0
        view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.3, animations: {
            flashView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                flashView.alpha = 0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }
    }
    
    func didWinGame() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showWinAlert()
        }
    }
}

