import SpriteKit

class CardNode: SKNode {
    let card: Card
    private var isFaceUp: Bool = false

    private let backgroundNode: SKShapeNode
    private let labelNode: SKLabelNode

    init(card: Card) {
        self.card = card

        // Create the card background (rounded rectangle)
        let rect = CGRect(x: -35, y: -50, width: 70, height: 100)
        self.backgroundNode = SKShapeNode(rect: rect, cornerRadius: 5)
        self.backgroundNode.fillColor = .blue // Face down color
        self.backgroundNode.strokeColor = .white
        self.backgroundNode.lineWidth = 2

        // Create the label for Rank/Suit
        self.labelNode = SKLabelNode(fontNamed: "Courier-Bold")
        self.labelNode.fontSize = 24
        self.labelNode.fontColor = .black
        self.labelNode.verticalAlignmentMode = .center
        self.labelNode.isHidden = true // Initially hidden because face down

        super.init()

        self.addChild(self.backgroundNode)
        self.addChild(self.labelNode)

        self.updateVisuals()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func flip() {
        self.isFaceUp.toggle()
        self.updateVisuals()
    }

    func setFaceUp(_ faceUp: Bool) {
        self.isFaceUp = faceUp
        self.updateVisuals()
    }

    private func updateVisuals() {
        if isFaceUp {
            self.backgroundNode.fillColor = .white
            self.labelNode.text = card.description
            self.labelNode.isHidden = false

            // Set color based on suit
            if card.suit == .hearts || card.suit == .diamonds {
                self.labelNode.fontColor = .red
            } else {
                self.labelNode.fontColor = .black
            }
        } else {
            self.backgroundNode.fillColor = .blue
            self.labelNode.isHidden = true
        }
    }
}
