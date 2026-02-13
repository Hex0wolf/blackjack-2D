import XCTest
@testable import Blackjack_2D

final class GameStateMachineTests: XCTestCase {
    func testTransitionMatrixMatchesPhaseContract() {
        let expected: [GamePhase: Set<GamePhase>] = [
            .idle: [.betting],
            .betting: [.initialDeal],
            .initialDeal: [.playerTurn, .dealerTurn, .settle],
            .playerTurn: [.dealerTurn, .settle],
            .dealerTurn: [.settle],
            .settle: [.rewards],
            .rewards: [.nextRound],
            .nextRound: [.betting]
        ]

        var machine = GameStateMachine()

        for phase in GamePhase.allCases {
            machine.reset(to: phase)
            XCTAssertEqual(machine.nextPhases, expected[phase, default: []], "Unexpected next phases for \(phase.rawValue)")

            for candidate in GamePhase.allCases {
                let canTransition = machine.canTransition(to: candidate)
                XCTAssertEqual(canTransition, expected[phase, default: []].contains(candidate), "Mismatch from \(phase.rawValue) to \(candidate.rawValue)")
            }
        }
    }

    func testHappyPathCycleCanRepeatRounds() {
        var machine = GameStateMachine()

        XCTAssertTrue(machine.transition(to: .betting))
        XCTAssertTrue(machine.transition(to: .initialDeal))
        XCTAssertTrue(machine.transition(to: .playerTurn))
        XCTAssertTrue(machine.transition(to: .dealerTurn))
        XCTAssertTrue(machine.transition(to: .settle))
        XCTAssertTrue(machine.transition(to: .rewards))
        XCTAssertTrue(machine.transition(to: .nextRound))
        XCTAssertTrue(machine.transition(to: .betting))
        XCTAssertEqual(machine.phase, .betting)
    }

    func testInvalidTransitionDoesNotMutatePhase() {
        var machine = GameStateMachine()
        machine.reset(to: .playerTurn)

        XCTAssertFalse(machine.transition(to: .betting))
        XCTAssertEqual(machine.phase, .playerTurn)
    }
}
