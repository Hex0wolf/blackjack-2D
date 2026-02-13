import XCTest
@testable import Blackjack_2D

final class BlackjackRulesEngineTests: XCTestCase {
    func testInitialDealEventOrderingContract() {
        let engine = StandardBlackjackRulesEngine()
        let context = RoundContext.bettingContext(
            shoe: TestFixtures.shoe(drawOrder: [
                TestFixtures.card(.ten, .hearts),
                TestFixtures.card(.five, .clubs),
                TestFixtures.card(.nine, .spades),
                TestFixtures.card(.seven, .diamonds)
            ]),
            bankroll: 1_000,
            bet: 100
        )

        let dealt = engine.dealInitialCards(context: context)

        XCTAssertEqual(dealt.phase, .playerTurn)
        XCTAssertEqual(Array(dealt.events.prefix(2)), [.roundStart, .chipBet])
        XCTAssertEqual(Array(dealt.events.suffix(4)), [.cardDealt, .cardDealt, .cardDealt, .cardDealt])
    }

    func testPlayDealerTurnDropsPriorEventsAndEmitsDealerOnlyEvents() {
        let engine = StandardBlackjackRulesEngine()
        var context = RoundContext.bettingContext(
            shoe: TestFixtures.shoe(drawOrder: [TestFixtures.card(.queen, .hearts)]),
            bankroll: 1_000,
            bet: 100
        )
        context.phase = .dealerTurn
        context.dealerHand = Hand(cards: [
            TestFixtures.card(.ten, .clubs),
            TestFixtures.card(.six, .spades)
        ])
        context.events = [.roundStart, .chipBet, .cardDealt]

        let resolved = engine.playDealerTurn(context: context)

        XCTAssertEqual(resolved.events, [.cardDealt, .bust])
        XCTAssertFalse(resolved.dealerHoleCardHidden)
    }

    func testDoubleConsumesBankrollAndForcesDealerTransition() {
        let engine = StandardBlackjackRulesEngine()
        let context = TestFixtures.playerTurnContext(
            bankroll: 1_000,
            bet: 100,
            playerCards: [
                TestFixtures.card(.five, .clubs),
                TestFixtures.card(.six, .diamonds)
            ],
            dealerCards: [
                TestFixtures.card(.ten, .spades),
                TestFixtures.card(.seven, .hearts)
            ],
            drawOrder: [TestFixtures.card(.ten, .diamonds)]
        )

        let doubled = engine.apply(action: .double, context: context)

        XCTAssertEqual(doubled.primaryBet, 200)
        XCTAssertEqual(doubled.bankroll, 900)
        XCTAssertTrue(doubled.primaryDoubled)
        XCTAssertTrue(doubled.primaryHasStood)
        XCTAssertEqual(doubled.phase, .dealerTurn)
        XCTAssertEqual(doubled.events, [.cardDealt])
        XCTAssertTrue(doubled.allowedActions.isEmpty)
    }

    func testSplitThenStandMovesPlayToSplitHand() {
        let engine = StandardBlackjackRulesEngine()
        let context = TestFixtures.playerTurnContext(
            bankroll: 1_000,
            bet: 100,
            playerCards: [
                TestFixtures.card(.eight, .hearts),
                TestFixtures.card(.eight, .clubs)
            ],
            dealerCards: [
                TestFixtures.card(.ten, .spades),
                TestFixtures.card(.five, .diamonds)
            ],
            drawOrder: [
                TestFixtures.card(.two, .spades),
                TestFixtures.card(.three, .hearts)
            ]
        )

        let split = engine.apply(action: .split, context: context)

        XCTAssertTrue(split.hasSplit)
        XCTAssertEqual(split.bankroll, 900)
        XCTAssertEqual(split.activeHand, .primary)
        XCTAssertEqual(split.events, [.cardDealt, .cardDealt])

        let afterPrimaryStand = engine.apply(action: .stand, context: split)
        XCTAssertEqual(afterPrimaryStand.phase, .playerTurn)
        XCTAssertEqual(afterPrimaryStand.activeHand, .split)
    }

    func testSplitHandBlackjackIsPaidAsNormalWin() {
        let engine = StandardBlackjackRulesEngine()
        var context = RoundContext.bettingContext(shoe: [], bankroll: 800, bet: 100)
        context.phase = .settle
        context.playerHand = Hand(cards: [
            TestFixtures.card(.ace, .spades),
            TestFixtures.card(.king, .hearts)
        ])
        context.splitHand = Hand(cards: [
            TestFixtures.card(.ten, .clubs),
            TestFixtures.card(.jack, .diamonds)
        ])
        context.dealerHand = Hand(cards: [
            TestFixtures.card(.ten, .diamonds),
            TestFixtures.card(.eight, .clubs)
        ])
        context.primaryBet = 100
        context.splitBet = 100
        context.bet = 100

        let result = engine.resolveRound(context: context)

        XCTAssertEqual(result.outcome, .playerWin)
        XCTAssertEqual(result.netPayout, 200)
        XCTAssertEqual(result.handResolutions[0].outcome, .playerWin)
        XCTAssertEqual(result.handResolutions[0].payout, 200)
        XCTAssertFalse(result.eventList.contains(.blackjack))
    }

    func testNaturalBlackjackSkipsPlayerTurnAndEmitsBlackjackOnSettlement() {
        let engine = StandardBlackjackRulesEngine()
        var context = RoundContext.bettingContext(
            shoe: TestFixtures.shoe(drawOrder: [
                TestFixtures.card(.ace, .spades),
                TestFixtures.card(.nine, .clubs),
                TestFixtures.card(.king, .hearts),
                TestFixtures.card(.seven, .diamonds)
            ]),
            bankroll: 1_000,
            bet: 100
        )

        context = engine.dealInitialCards(context: context)

        XCTAssertEqual(context.phase, .dealerTurn)
        XCTAssertTrue(context.allowedActions.isEmpty)

        context = engine.playDealerTurn(context: context)
        XCTAssertEqual(context.events, [])

        let result = engine.resolveRound(context: context)
        XCTAssertEqual(result.outcome, .blackjack)
        XCTAssertEqual(result.eventList.first, .blackjack)
    }

    func testRoundEventsFollowDealResolveSettleOrdering() {
        let engine = StandardBlackjackRulesEngine()
        var context = RoundContext.bettingContext(
            shoe: TestFixtures.shoe(drawOrder: [
                TestFixtures.card(.ten, .spades),
                TestFixtures.card(.seven, .hearts),
                TestFixtures.card(.nine, .clubs),
                TestFixtures.card(.nine, .diamonds),
                TestFixtures.card(.six, .clubs)
            ]),
            bankroll: 1_000,
            bet: 100
        )

        context = engine.dealInitialCards(context: context)
        XCTAssertEqual(Array(context.events.prefix(2)), [.roundStart, .chipBet])
        XCTAssertEqual(Array(context.events.suffix(4)), [.cardDealt, .cardDealt, .cardDealt, .cardDealt])

        context = engine.apply(action: .stand, context: context)
        XCTAssertEqual(context.events, [])
        XCTAssertEqual(context.phase, .dealerTurn)

        context = engine.playDealerTurn(context: context)
        XCTAssertEqual(context.events, [.cardDealt, .bust])

        let result = engine.resolveRound(context: context)
        XCTAssertEqual(result.eventList, [.playerWin])
        XCTAssertEqual(result.outcome, .playerWin)
    }
}
