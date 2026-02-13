import XCTest
@testable import Blackjack_2D

final class HandTests: XCTestCase {
    func testAceAndSixIsSoftSeventeen() {
        let hand = Hand(cards: [
            TestFixtures.card(.ace, .spades),
            TestFixtures.card(.six, .hearts)
        ])

        XCTAssertEqual(hand.hardValue, 7)
        XCTAssertEqual(hand.bestValue, 17)
        XCTAssertTrue(hand.isSoft)
        XCTAssertFalse(hand.isBust)
    }

    func testTwoAcesAndNineResolvesToTwentyOne() {
        let hand = Hand(cards: [
            TestFixtures.card(.ace, .clubs),
            TestFixtures.card(.ace, .diamonds),
            TestFixtures.card(.nine, .hearts)
        ])

        XCTAssertEqual(hand.hardValue, 11)
        XCTAssertEqual(hand.bestValue, 21)
        XCTAssertTrue(hand.isSoft)
        XCTAssertFalse(hand.isBust)
    }

    func testMultipleAcesCanStillBust() {
        let hand = Hand(cards: [
            TestFixtures.card(.ace, .clubs),
            TestFixtures.card(.ace, .diamonds),
            TestFixtures.card(.queen, .hearts),
            TestFixtures.card(.king, .spades)
        ])

        XCTAssertEqual(hand.hardValue, 22)
        XCTAssertEqual(hand.bestValue, 22)
        XCTAssertFalse(hand.isSoft)
        XCTAssertTrue(hand.isBust)
    }

    func testBlackjackRequiresExactlyTwoCards() {
        let blackjack = Hand(cards: [
            TestFixtures.card(.ace, .spades),
            TestFixtures.card(.king, .hearts)
        ])

        let twentyOneInThreeCards = Hand(cards: [
            TestFixtures.card(.ace, .spades),
            TestFixtures.card(.five, .hearts),
            TestFixtures.card(.five, .clubs)
        ])

        XCTAssertTrue(blackjack.isBlackjack)
        XCTAssertFalse(twentyOneInThreeCards.isBlackjack)
        XCTAssertEqual(twentyOneInThreeCards.bestValue, 21)
    }
}
