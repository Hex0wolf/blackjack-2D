import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var game: BlackjackGame!

    // UI Elements
    var dealerLabel: SKLabelNode!
    var playerLabel: SKLabelNode!
    var messageLabel: SKLabelNode!

    var hitButton: ButtonNode!
    var standButton: ButtonNode!
    var dealButton: ButtonNode!

    // Card Containers (Nodes to hold cards for easier positioning)
    var dealerCardsNode: SKNode!
    var playerCardsNode: SKNode!
    
    override func didMove(to view: SKView) {
        self.removeAllChildren() // Clean up any nodes from .sks file
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5) // Ensure center anchor for layout
        self.backgroundColor = SKColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0) // Green felt color

        self.game = BlackjackGame()

        setupUI()
        startNewGame()
    }

    func setupUI() {
        // Labels
        dealerLabel = SKLabelNode(fontNamed: "Courier-Bold")
        dealerLabel.text = "Dealer: 0"
        dealerLabel.fontSize = 24
        self.addChild(dealerLabel)

        playerLabel = SKLabelNode(fontNamed: "Courier-Bold")
        playerLabel.text = "Player: 0"
        playerLabel.fontSize = 24
        self.addChild(playerLabel)

        messageLabel = SKLabelNode(fontNamed: "Courier-Bold")
        messageLabel.text = "Welcome!"
        messageLabel.fontSize = 28
        messageLabel.fontColor = .yellow
        self.addChild(messageLabel)
        
        // Card Containers
        dealerCardsNode = SKNode()
        self.addChild(dealerCardsNode)

        playerCardsNode = SKNode()
        self.addChild(playerCardsNode)

        // Buttons
        let buttonSize = CGSize(width: 120, height: 50)

        hitButton = ButtonNode(text: "HIT", size: buttonSize) { [weak self] in
            self?.handleHit()
        }
        self.addChild(hitButton)
        
        standButton = ButtonNode(text: "STAND", size: buttonSize) { [weak self] in
            self?.handleStand()
        }
        self.addChild(standButton)
        
        dealButton = ButtonNode(text: "DEAL", size: buttonSize) { [weak self] in
            self?.startNewGame()
        }
        self.addChild(dealButton)

        // Initial Layout
        layoutScene()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        layoutScene()
    }
    
    func layoutScene() {
        let w = self.size.width
        let h = self.size.height
        let safeAreaInsets = self.view?.safeAreaInsets ?? .zero

        // Determine layout based on aspect ratio
        let isPortrait = h > w

        // Dealer Area (Top)
        dealerLabel.position = CGPoint(x: 0, y: h/2 - safeAreaInsets.top - 40)
        dealerCardsNode.position = CGPoint(x: 0, y: dealerLabel.position.y - 80)

        // Buttons Area (Bottom)
        let buttonY = -h/2 + safeAreaInsets.bottom + 60
        hitButton.position = CGPoint(x: -80, y: buttonY)
        standButton.position = CGPoint(x: 80, y: buttonY)
        dealButton.position = CGPoint(x: 0, y: buttonY) // Replaces Hit/Stand when game over

        // Player Area (Above Buttons)
        playerLabel.position = CGPoint(x: 0, y: buttonY + 80)
        playerCardsNode.position = CGPoint(x: 0, y: playerLabel.position.y + 60)

        // Message Area (Center)
        messageLabel.position = CGPoint(x: 0, y: 0)
    }
    
    func startNewGame() {
        game.start()
        updateUI()

        if game.gameState == .playing {
            hitButton.isHidden = false
            standButton.isHidden = false
            dealButton.isHidden = true
        } else {
            showGameOverUI()
        }
    }
    
    func handleHit() {
        game.playerHit()
        updateUI()

        if game.gameState == .gameOver {
            showGameOverUI()
        }
    }
    
    func handleStand() {
        game.playerStand()
        updateUI() // Update to show dealer's turn start
        
        // Start dealer turn animation
        playDealerTurn()
    }
    
    func playDealerTurn() {
        // Dealer logic happens step-by-step
        if game.gameState == .dealerTurn {
            let dealt = game.dealerStep()
            updateUI()

            if dealt {
                // If dealer took a card, wait and do it again
                let wait = SKAction.wait(forDuration: 1.0)
                let nextStep = SKAction.run { [weak self] in
                    self?.playDealerTurn()
                }
                self.run(SKAction.sequence([wait, nextStep]))
            } else {
                // Dealer finished (stood or busted)
                showGameOverUI()
            }
        } else {
             showGameOverUI()
        }
    }
    
    func showGameOverUI() {
        hitButton.isHidden = true
        standButton.isHidden = true
        dealButton.isHidden = false
        updateUI()
    }
    
    func updateUI() {
        // Update Labels
        // Hide dealer score if playing (first card hidden)
        // Wait, if playing, one card is hidden.
        // I should calculate visible score.
        // Actually, for arcade style, maybe just show "? + X"

        if game.gameState == .playing {
            // Dealer has one hole card.
            // game.dealerHand.cards[0] is typically hole card?
            // In my Deck logic: dealer gets 2nd (hole) and 4th (up).
            // So index 0 is hole.
            if game.dealerHand.cards.count >= 2 {
                let upCardValue = game.dealerHand.cards[1].rank.value // Simplified score display
                dealerLabel.text = "Dealer: \(upCardValue) + ?"
            } else {
                 dealerLabel.text = "Dealer: 0"
            }
        } else {
            dealerLabel.text = "Dealer: \(game.dealerHand.score)"
        }

        playerLabel.text = "Player: \(game.playerHand.score)"
        messageLabel.text = game.message

        // Render Cards
        renderHand(hand: game.dealerHand, node: dealerCardsNode, hideFirst: (game.gameState == .playing))
        renderHand(hand: game.playerHand, node: playerCardsNode, hideFirst: false)
    }
    
    func renderHand(hand: Hand, node: SKNode, hideFirst: Bool) {
        node.removeAllChildren()

        if hand.cards.isEmpty { return }

        let cardWidth: CGFloat = 70
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(hand.cards.count) * cardWidth + CGFloat(hand.cards.count - 1) * spacing
        var startX = -totalWidth / 2 + cardWidth / 2

        for (index, card) in hand.cards.enumerated() {
            let cardNode = CardNode(card: card)
            cardNode.position = CGPoint(x: startX, y: 0)

            if hideFirst && index == 0 {
                cardNode.setFaceUp(false)
            } else {
                cardNode.setFaceUp(true)
            }

            node.addChild(cardNode)
            startX += cardWidth + spacing
        }
    }
}
