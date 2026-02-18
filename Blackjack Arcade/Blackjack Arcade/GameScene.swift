//
//  GameScene.swift
//  Blackjack Arcade
//
//  Created by Ethan Graham on 2/17/26.
//

import SpriteKit
import GameplayKit

class CardNode: SKSpriteNode {
    let rank: String
    let suit: String
    
    init(rank: String, suit: String) {
        self.rank = rank
        self.suit = suit
        super.init(texture: nil, color: .white, size: CGSize(width: 100, height: 140))
        setupVisuals()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupVisuals() {
        let label = SKLabelNode(text: "\(rank)\n\(suit)")
        label.numberOfLines = 2
        label.fontSize = 24
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)
        
        let border = SKShapeNode(rectOf: size, cornerRadius: 8)
        border.strokeColor = .black
        border.lineWidth = 2
        addChild(border)
    }
}

class ButtonNode: SKSpriteNode {
    var action: (() -> Void)?

    init(color: UIColor, size: CGSize, text: String, action: @escaping () -> Void) {
        self.action = action
        super.init(texture: nil, color: color, size: size)
        
        let label = SKLabelNode(text: text)
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)
        
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        run(scaleDown)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        run(scaleUp) {
            self.action?()
        }
    }
}

class GameScene: SKScene {

    private var dealerHandNode: SKNode!
    private var playerHandNode: SKNode!
    private var deckNode: SKShapeNode!
    private var hitButton: ButtonNode!
    private var standButton: ButtonNode!
    private var messageLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var betLabel: SKLabelNode!

    private var deck: [(rank: String, suit: String)] = []
    private let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
    private let suits = ["♠️", "♥️", "♣️", "♦️"]
    
    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = SKColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)

        // Ensure anchor point is center for easier layout
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupDeck()
        setupUI()
        startNewGame()
    }

    private func setupDeck() {
        deck = []
        for suit in suits {
            for rank in ranks {
                deck.append((rank: rank, suit: suit))
            }
        }
        deck.shuffle()
    }
    
    private func setupUI() {
        let dealerLabel = SKLabelNode(text: "Dealer's Hand")
        dealerLabel.position = CGPoint(x: 0, y: size.height * 0.35)
        dealerLabel.fontSize = 24
        dealerLabel.fontName = "Helvetica-Bold"
        addChild(dealerLabel)

        dealerHandNode = SKNode()
        dealerHandNode.position = CGPoint(x: 0, y: size.height * 0.20)
        addChild(dealerHandNode)

        let playerLabel = SKLabelNode(text: "Player's Hand")
        playerLabel.position = CGPoint(x: 0, y: -size.height * 0.05)
        playerLabel.fontSize = 24
        playerLabel.fontName = "Helvetica-Bold"
        addChild(playerLabel)

        playerHandNode = SKNode()
        playerHandNode.position = CGPoint(x: 0, y: -size.height * 0.20)
        addChild(playerHandNode)

        deckNode = SKShapeNode(rectOf: CGSize(width: 100, height: 140), cornerRadius: 8)
        deckNode.fillColor = .gray
        deckNode.strokeColor = .white
        deckNode.position = CGPoint(x: size.width * 0.35, y: size.height * 0.1)
        addChild(deckNode)

        let deckLabel = SKLabelNode(text: "DECK")
        deckLabel.fontSize = 14
        deckLabel.fontColor = .black
        deckLabel.verticalAlignmentMode = .center
        deckNode.addChild(deckLabel)

        hitButton = ButtonNode(color: .blue, size: CGSize(width: 120, height: 50), text: "HIT") { [weak self] in
            self?.hit()
        }
        hitButton.position = CGPoint(x: -size.width * 0.2, y: -size.height * 0.40)
        addChild(hitButton)

        standButton = ButtonNode(color: .red, size: CGSize(width: 120, height: 50), text: "STAND") { [weak self] in
            self?.stand()
        }
        standButton.position = CGPoint(x: size.width * 0.2, y: -size.height * 0.40)
        addChild(standButton)

        messageLabel = SKLabelNode(text: "Welcome!")
        messageLabel.fontSize = 30
        messageLabel.fontColor = .yellow
        messageLabel.position = CGPoint(x: 0, y: 0)
        addChild(messageLabel)
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontSize = 20
        scoreLabel.fontName = "Helvetica-Bold"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: -size.width * 0.45, y: size.height * 0.45)
        addChild(scoreLabel)

        betLabel = SKLabelNode(text: "Bet: 100")
        betLabel.fontSize = 20
        betLabel.fontName = "Helvetica-Bold"
        betLabel.horizontalAlignmentMode = .right
        betLabel.position = CGPoint(x: size.width * 0.45, y: size.height * 0.45)
        addChild(betLabel)
    }
    
    private func startNewGame() {
        setupDeck()
        dealerHandNode.removeAllChildren()
        playerHandNode.removeAllChildren()
        messageLabel.text = "Good Luck!"

        dealCard(to: playerHandNode, delay: 0.2)
        dealCard(to: dealerHandNode, delay: 0.6)
        dealCard(to: playerHandNode, delay: 1.0)
        dealCard(to: dealerHandNode, delay: 1.4)
    }
    
    private func dealCard(to handNode: SKNode, delay: TimeInterval = 0.0) {
        guard !deck.isEmpty else { return }

        let cardData = deck.removeFirst()
        // Wait to create node until delay passes
        let dealAction = SKAction.run { [weak self, weak handNode] in
            guard let self = self, let handNode = handNode else { return }

            let card = CardNode(rank: cardData.rank, suit: cardData.suit)
            // Start position relative to handNode
            let startPos = self.convert(self.deckNode.position, to: handNode)
            card.position = startPos
            card.setScale(0.1)
            card.zPosition = 10 + CGFloat(handNode.children.count)
            handNode.addChild(card)

            let targetX = CGFloat(handNode.children.count - 1) * 60 - 60
            let targetPos = CGPoint(x: targetX, y: 0)

            let moveAction = SKAction.move(to: targetPos, duration: 0.3)
            let scaleAction = SKAction.scale(to: 1.0, duration: 0.3)
            // Add a small rotation for flavor
            let rotateAction = SKAction.rotate(byAngle: CGFloat.random(in: -0.1...0.1), duration: 0.3)

            let group = SKAction.group([moveAction, scaleAction, rotateAction])
            card.run(group)
        }

        run(SKAction.sequence([SKAction.wait(forDuration: delay), dealAction]))
    }
    
    private func hit() {
        messageLabel.text = "Player Hits"
        dealCard(to: playerHandNode)
    }
    
    private func stand() {
        messageLabel.text = "Player Stands"
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                // Just deal one card to dealer for now
                self?.dealCard(to: self?.dealerHandNode ?? SKNode())
            }
        ]))
    }
}
