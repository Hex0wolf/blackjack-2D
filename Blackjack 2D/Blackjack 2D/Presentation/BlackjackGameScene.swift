import SpriteKit

final class BlackjackGameScene: SKScene {
    private let tableNode = SKShapeNode()
    private let dealerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let dealerValueLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let playerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let playerValueLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let splitLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let splitValueLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let phaseLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.03, green: 0.16, blue: 0.10, alpha: 1.0)
        setupNodes()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.03, green: 0.16, blue: 0.10, alpha: 1.0)
        setupNodes()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutNodes()
    }

    func render(snapshot: GameSnapshot) {
        dealerLabel.text = "Dealer: \(snapshot.dealerCards)"
        dealerValueLabel.text = "Value: \(snapshot.dealerValue)"

        playerLabel.text = "Player: \(snapshot.playerCards)"
        playerValueLabel.text = "Value: \(snapshot.playerValue)"

        if let splitCards = snapshot.splitCards,
           let splitValue = snapshot.splitValue {
            splitLabel.text = "Split: \(splitCards)"
            splitValueLabel.text = "Value: \(splitValue)"
            splitLabel.alpha = 1
            splitValueLabel.alpha = 1
        } else {
            splitLabel.text = ""
            splitValueLabel.text = ""
            splitLabel.alpha = 0
            splitValueLabel.alpha = 0
        }

        phaseLabel.text = "Phase: \(snapshot.phase.rawValue.uppercased())"
        statusLabel.text = snapshot.status

        applyEventEffects(snapshot.recentEvents)
    }

    private func setupNodes() {
        tableNode.strokeColor = SKColor(red: 0.34, green: 0.70, blue: 0.40, alpha: 1)
        tableNode.lineWidth = 4
        tableNode.fillColor = SKColor(red: 0.06, green: 0.28, blue: 0.18, alpha: 1)
        addChild(tableNode)

        [dealerLabel, dealerValueLabel, playerLabel, playerValueLabel, splitLabel, splitValueLabel, phaseLabel, statusLabel].forEach {
            $0.fontSize = 26
            $0.fontColor = .white
            $0.horizontalAlignmentMode = .center
            $0.verticalAlignmentMode = .center
            addChild($0)
        }

        statusLabel.fontSize = 24
        phaseLabel.fontSize = 20
        layoutNodes()
    }

    private func layoutNodes() {
        tableNode.path = CGPath(
            roundedRect: CGRect(
                x: -size.width * 0.47,
                y: -size.height * 0.40,
                width: size.width * 0.94,
                height: size.height * 0.80
            ),
            cornerWidth: 28,
            cornerHeight: 28,
            transform: nil
        )

        dealerLabel.position = CGPoint(x: 0, y: size.height * 0.22)
        dealerValueLabel.position = CGPoint(x: 0, y: size.height * 0.16)
        playerLabel.position = CGPoint(x: 0, y: -size.height * 0.02)
        playerValueLabel.position = CGPoint(x: 0, y: -size.height * 0.08)
        splitLabel.position = CGPoint(x: 0, y: -size.height * 0.20)
        splitValueLabel.position = CGPoint(x: 0, y: -size.height * 0.26)
        phaseLabel.position = CGPoint(x: 0, y: size.height * 0.33)
        statusLabel.position = CGPoint(x: 0, y: -size.height * 0.34)
    }

    private func applyEventEffects(_ events: [RoundEvent]) {
        guard let event = events.last else { return }

        switch event {
        case .blackjack, .levelUp:
            runFlash(color: SKColor(red: 0.95, green: 0.90, blue: 0.40, alpha: 0.35))
            runCameraShake()
        case .winBig:
            runFlash(color: SKColor(red: 0.45, green: 0.88, blue: 0.55, alpha: 0.30))
        case .bust, .dealerWin:
            runFlash(color: SKColor(red: 0.88, green: 0.30, blue: 0.30, alpha: 0.25))
        case .playerWin, .unlock:
            runFlash(color: SKColor(red: 0.30, green: 0.65, blue: 0.90, alpha: 0.20))
        default:
            break
        }
    }

    private func runFlash(color: SKColor) {
        let flashNode = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        flashNode.fillColor = color
        flashNode.strokeColor = .clear
        flashNode.zPosition = 100
        flashNode.alpha = 0
        addChild(flashNode)

        let sequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.06),
            SKAction.fadeOut(withDuration: 0.24),
            SKAction.removeFromParent()
        ])
        flashNode.run(sequence)
    }

    private func runCameraShake() {
        let amplitude: CGFloat = 8
        let sequence = SKAction.sequence([
            SKAction.moveBy(x: amplitude, y: 0, duration: 0.03),
            SKAction.moveBy(x: -amplitude * 2, y: 0, duration: 0.06),
            SKAction.moveBy(x: amplitude, y: 0, duration: 0.03)
        ])
        run(sequence)
    }
}
