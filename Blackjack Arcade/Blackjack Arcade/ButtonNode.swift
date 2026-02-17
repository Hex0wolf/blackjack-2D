import SpriteKit

class ButtonNode: SKNode {
    var action: (() -> Void)?
    private let backgroundNode: SKShapeNode
    private let labelNode: SKLabelNode
    private let size: CGSize

    init(text: String, size: CGSize, action: @escaping () -> Void) {
        self.action = action
        self.size = size

        let rect = CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size)
        self.backgroundNode = SKShapeNode(rect: rect, cornerRadius: 10)
        self.backgroundNode.fillColor = .gray
        self.backgroundNode.strokeColor = .white
        self.backgroundNode.lineWidth = 2

        self.labelNode = SKLabelNode(text: text)
        self.labelNode.fontName = "Courier-Bold"
        self.labelNode.fontSize = 20
        self.labelNode.fontColor = .white
        self.labelNode.verticalAlignmentMode = .center
        self.labelNode.zPosition = 1 // Ensure label is above background

        super.init()

        self.isUserInteractionEnabled = true
        self.addChild(backgroundNode)
        self.addChild(labelNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundNode.fillColor = .darkGray
        // Scale down slightly for feedback
        self.run(SKAction.scale(to: 0.95, duration: 0.1))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundNode.fillColor = .gray
        self.run(SKAction.scale(to: 1.0, duration: 0.1))

        // Only trigger action if touch ends inside the button
        if let touch = touches.first {
            let location = touch.location(in: self)
            if self.backgroundNode.contains(location) {
                action?()
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundNode.fillColor = .gray
        self.run(SKAction.scale(to: 1.0, duration: 0.1))
    }

    func setText(_ text: String) {
        self.labelNode.text = text
    }
}
