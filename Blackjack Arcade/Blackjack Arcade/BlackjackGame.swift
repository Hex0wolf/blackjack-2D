import Foundation

enum GameState {
    case playing
    case dealerTurn
    case gameOver
}

class BlackjackGame {
    var deck: Deck
    var playerHand: Hand = Hand()
    var dealerHand: Hand = Hand()
    var gameState: GameState = .gameOver
    var message: String = "Press Deal to start"

    init() {
        self.deck = Deck()
    }

    func start() {
        self.deck = Deck() // New shuffled deck
        self.playerHand.reset()
        self.dealerHand.reset()

        // Deal initial cards
        // Player gets 1st and 3rd card
        // Dealer gets 2nd (hole) and 4th (up) card
        if let card1 = self.deck.deal() { self.playerHand.add(card1) }
        if let card2 = self.deck.deal() { self.dealerHand.add(card2) }
        if let card3 = self.deck.deal() { self.playerHand.add(card3) }
        if let card4 = self.deck.deal() { self.dealerHand.add(card4) }

        self.gameState = .playing
        self.message = "Hit or Stand?"

        // Check for natural Blackjack immediately
        if self.playerHand.isBlackjack {
             self.endGame()
        }
    }

    func playerHit() {
        guard self.gameState == .playing else { return }

        if let card = self.deck.deal() {
            self.playerHand.add(card)

            if self.playerHand.isBusted {
                self.message = "Bust! You lose."
                self.gameState = .gameOver
            }
        }
    }

    func playerStand() {
        guard self.gameState == .playing else { return }
        self.gameState = .dealerTurn
        self.message = "Dealer's Turn..."
    }

    // Returns true if a card was dealt, false if dealer stands or busts
    func dealerStep() -> Bool {
        guard self.gameState == .dealerTurn else { return false }

        if self.dealerHand.score < 17 {
            if let card = self.deck.deal() {
                self.dealerHand.add(card)
                return true
            }
        }

        self.endGame()
        return false
    }

    func endGame() {
        self.gameState = .gameOver

        let playerScore = self.playerHand.score
        let dealerScore = self.dealerHand.score

        if self.playerHand.isBusted {
             self.message = "Bust! You lose."
        } else if self.playerHand.isBlackjack && !self.dealerHand.isBlackjack {
             self.message = "Blackjack! You win!"
        } else if self.dealerHand.isBusted {
            self.message = "Dealer busts! You win!"
        } else if playerScore > dealerScore {
            self.message = "You win!"
        } else if playerScore < dealerScore {
            self.message = "Dealer wins."
        } else {
            self.message = "Push."
        }
    }
}
