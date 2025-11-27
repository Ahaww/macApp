//
//  CardView.swift
//  temp
//
//  Created by F04 on 2025/11/20.
//

import UIKit

class CardView: UIView {
    
    private let card: Card
    private let emojiLabel: UILabel
    private let backView: UIView
    
    var onTap: (() -> Void)?
    
    init(card: Card) {
        self.card = card
        self.emojiLabel = UILabel()
        self.backView = UIView()
        
        super.init(frame: .zero)
        
        setupView()
        setupGesture()
        updateCardState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        layer.cornerRadius = 12
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemTeal.cgColor
        clipsToBounds = true
        
        // 设置背面
        backView.backgroundColor = UIColor.systemTeal
        backView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backView)
        
        // 设置emoji标签
        emojiLabel.text = card.emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 40)
        emojiLabel.textAlignment = .center
        emojiLabel.backgroundColor = UIColor.white
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: topAnchor),
            backView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            emojiLabel.topAnchor.constraint(equalTo: topAnchor),
            emojiLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            emojiLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            emojiLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func cardTapped() {
        onTap?()
    }
    
    func updateCardState() {
        switch card.state {
        case .faceDown:
            backView.alpha = 1
            emojiLabel.alpha = 0
            transform = .identity
            alpha = 1
        case .faceUp:
            backView.alpha = 0
            emojiLabel.alpha = 1
            transform = .identity
            alpha = 1
        case .matched:
            backView.alpha = 0
            emojiLabel.alpha = 1
            layer.borderColor = UIColor.systemGreen.cgColor
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            transform = .identity
            alpha = 1
        case .disappeared:
            // 直接设置为消失状态，不依赖动画
            backView.alpha = 0
            emojiLabel.alpha = 0
            backgroundColor = .clear
            layer.borderWidth = 0
            transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            alpha = 0
        }
    }
    
    func flipWithAnimation() {
        UIView.transition(with: self, duration:0.6, options: .transitionFlipFromRight, animations: {
            self.updateCardState()
        }, completion: { _ in
            // 如果是匹配状态，添加脉冲动画
            if self.card.state == .matched {
                self.addMatchAnimation()
            }
            // 如果是消失状态，添加消失动画
            else if self.card.state == .disappeared {
                self.disappearWithAnimation()
            }
        })
    }
    
    func disappearWithAnimation() {
        UIView.animate(withDuration: 1.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.alpha = 0
        }, completion: { _ in
            // 动画完成后更新卡片状态
            self.updateCardState()
        })
    }
    
    private func addMatchAnimation() {
        // 脉冲动画
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 0.3
        pulse.fromValue = 1.0
        pulse.toValue = 1.1
        pulse.autoreverses = true
        pulse.repeatCount = 2
        layer.add(pulse, forKey: "pulse")
        
        // 颜色渐变动画
        let colorChange = CABasicAnimation(keyPath: "backgroundColor")
        colorChange.duration = 0.5
        colorChange.toValue = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
        colorChange.fillMode = .forwards
        colorChange.isRemovedOnCompletion = false
        layer.add(colorChange, forKey: "colorChange")
    }
}