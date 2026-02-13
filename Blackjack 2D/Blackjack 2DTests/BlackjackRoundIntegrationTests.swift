import XCTest
@testable import Blackjack_2D

final class BlackjackRoundIntegrationTests: XCTestCase {
    func testDeterministicRoundFromBetToSettlement() {
        let engine = StandardBlackjackRulesEngine()
        let progression = DefaultProgressionService()

        var profile = PlayerProfile.default
        let bet = 100

        profile.chips -= bet
        var context = RoundContext.bettingContext(
            shoe: TestFixtures.shoe(drawOrder: [
                TestFixtures.card(.ten, .spades),
                TestFixtures.card(.seven, .hearts),
                TestFixtures.card(.nine, .clubs),
                TestFixtures.card(.nine, .diamonds),
                TestFixtures.card(.six, .clubs)
            ]),
            bankroll: profile.chips,
            bet: bet
        )

        context = engine.dealInitialCards(context: context)
        XCTAssertEqual(context.phase, .playerTurn)

        context = engine.apply(action: .stand, context: context)
        XCTAssertEqual(context.phase, .dealerTurn)

        context = engine.playDealerTurn(context: context)
        XCTAssertEqual(context.events, [.cardDealt, .bust])

        let result = engine.resolveRound(context: context)
        XCTAssertEqual(result.outcome, .playerWin)
        XCTAssertEqual(result.netPayout, 100)

        let totalCredit = context.committedBet + result.netPayout
        profile.chips += totalCredit

        let delta = progression.applyRound(result: result, profile: profile, modifier: nil)
        XCTAssertEqual(delta.events, [])
        XCTAssertEqual(delta.profile.chips, 1_100)
    }

    func testSplitBranchWithMixedOutcomesSettlesDeterministically() {
        let engine = StandardBlackjackRulesEngine()

        var context = RoundContext.bettingContext(
            shoe: TestFixtures.shoe(drawOrder: [
                TestFixtures.card(.eight, .hearts),
                TestFixtures.card(.ten, .clubs),
                TestFixtures.card(.eight, .diamonds),
                TestFixtures.card(.seven, .spades),
                TestFixtures.card(.ten, .hearts),
                TestFixtures.card(.nine, .clubs),
                TestFixtures.card(.king, .diamonds)
            ]),
            bankroll: 900,
            bet: 100
        )

        context = engine.dealInitialCards(context: context)
        XCTAssertEqual(context.phase, .playerTurn)
        XCTAssertTrue(context.allowedActions.contains(.split))

        context = engine.apply(action: .split, context: context)
        XCTAssertTrue(context.hasSplit)
        XCTAssertEqual(context.activeHand, .primary)

        context = engine.apply(action: .stand, context: context)
        XCTAssertEqual(context.activeHand, .split)
        XCTAssertEqual(context.phase, .playerTurn)

        context = engine.apply(action: .hit, context: context)
        XCTAssertEqual(context.phase, .dealerTurn)
        XCTAssertTrue(context.hand(for: .split).isBust)

        context = engine.playDealerTurn(context: context)
        XCTAssertEqual(context.dealerHand.bestValue, 17)
        XCTAssertEqual(context.events, [])

        let result = engine.resolveRound(context: context)
        XCTAssertEqual(result.handResolutions.count, 2)
        XCTAssertEqual(result.handResolutions[0].outcome, .playerWin)
        XCTAssertEqual(result.handResolutions[1].outcome, .bust)
        XCTAssertEqual(result.netPayout, 0)
    }
}
