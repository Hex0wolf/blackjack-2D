import XCTest
@testable import Blackjack_2D

final class BlackjackSmokeTests: XCTestCase {
    func testDeckFactoryIsDeterministicWithSeed() {
        let first = DeckFactory.makeShuffledShoe(deckCount: 1, seed: 42)
        let second = DeckFactory.makeShuffledShoe(deckCount: 1, seed: 42)
        let third = DeckFactory.makeShuffledShoe(deckCount: 1, seed: 99)

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, third)
        XCTAssertEqual(first.count, 52)
    }

    func testDealerStandsOnSoft17() {
        let engine = StandardBlackjackRulesEngine()

        var context = RoundContext.bettingContext(
            shoe: TestFixtures.shoe(drawOrder: [TestFixtures.card(.five, .diamonds)]),
            bankroll: 1_000,
            bet: 100
        )
        context.phase = .dealerTurn
        context.dealerHand = Hand(cards: [
            TestFixtures.card(.ace, .spades),
            TestFixtures.card(.six, .hearts)
        ])
        context.playerHand = Hand(cards: [
            TestFixtures.card(.ten, .clubs),
            TestFixtures.card(.nine, .diamonds)
        ])

        let resolved = engine.playDealerTurn(context: context)

        XCTAssertEqual(resolved.dealerHand.cards.count, 2)
        XCTAssertEqual(resolved.dealerHand.bestValue, 17)
        XCTAssertFalse(resolved.dealerHoleCardHidden)
    }

    func testAllowedActionsIncludeSplitAndDoubleOnOpeningPair() {
        let engine = StandardBlackjackRulesEngine()
        let context = TestFixtures.playerTurnContext(
            bankroll: 1_000,
            bet: 100,
            playerCards: [
                TestFixtures.card(.eight, .hearts),
                TestFixtures.card(.eight, .clubs)
            ],
            dealerCards: [
                TestFixtures.card(.queen, .spades),
                TestFixtures.card(.five, .clubs)
            ]
        )

        let actions = engine.allowedActions(context: context)

        XCTAssertTrue(actions.contains(.hit))
        XCTAssertTrue(actions.contains(.stand))
        XCTAssertTrue(actions.contains(.double))
        XCTAssertTrue(actions.contains(.split))
    }

    func testBlackjackPaysThreeToTwo() {
        let engine = StandardBlackjackRulesEngine()

        var context = RoundContext.bettingContext(shoe: [], bankroll: 900, bet: 100)
        context.phase = .settle
        context.dealerHoleCardHidden = false
        context.playerHand = Hand(cards: [
            TestFixtures.card(.ace, .spades),
            TestFixtures.card(.king, .hearts)
        ])
        context.dealerHand = Hand(cards: [
            TestFixtures.card(.ten, .clubs),
            TestFixtures.card(.seven, .diamonds)
        ])
        context.primaryBet = 100
        context.bet = 100

        let result = engine.resolveRound(context: context)

        XCTAssertEqual(result.outcome, .blackjack)
        XCTAssertEqual(result.netPayout, 150)
        XCTAssertEqual(result.handResolutions.count, 1)
        XCTAssertEqual(result.handResolutions[0].payout, 250)
    }

    func testGameStateMachineRejectsInvalidTransition() {
        var machine = GameStateMachine()

        XCTAssertTrue(machine.transition(to: .betting))
        XCTAssertFalse(machine.transition(to: .dealerTurn))
        XCTAssertEqual(machine.phase, .betting)
    }
}
