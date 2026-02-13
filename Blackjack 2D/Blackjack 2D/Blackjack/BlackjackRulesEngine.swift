import Foundation

protocol BlackjackRulesEngine {
    func allowedActions(context: RoundContext) -> Set<PlayerAction>
    func apply(action: PlayerAction, context: RoundContext) -> RoundContext
    func resolveRound(context: RoundContext) -> RoundResult
}

struct StandardBlackjackRulesEngine: BlackjackRulesEngine {
    func dealInitialCards(context: RoundContext) -> RoundContext {
        var updated = context
        updated.phase = .initialDeal
        updated.events = [.roundStart, .chipBet]
        updated.dealerHand = Hand()
        updated.playerHand = Hand()
        updated.splitHand = nil
        updated.activeHand = .primary
        updated.primaryHasStood = false
        updated.splitHasStood = false
        updated.primaryDoubled = false
        updated.splitDoubled = false
        updated.splitBet = nil
        updated.primaryBet = updated.bet
        updated.dealerHoleCardHidden = true

        for _ in 0..<2 {
            dealCard(to: .primary, context: &updated)
            dealCardToDealer(context: &updated)
        }

        if updated.playerHand.isBlackjack || updated.dealerHand.isBlackjack {
            updated.phase = .dealerTurn
            updated.allowedActions = []
        } else {
            updated.phase = .playerTurn
            updated.allowedActions = allowedActions(context: updated)
        }

        return updated
    }

    func playDealerTurn(context: RoundContext) -> RoundContext {
        var updated = context
        updated.phase = .dealerTurn
        updated.dealerHoleCardHidden = false
        updated.events = []

        while shouldDealerDraw(hand: updated.dealerHand) {
            guard let card = updated.drawCard() else { break }
            updated.dealerHand.addCard(card)
            updated.events.append(.cardDealt)
        }

        if updated.dealerHand.isBust {
            updated.events.append(.bust)
        }

        return updated
    }

    func allowedActions(context: RoundContext) -> Set<PlayerAction> {
        guard context.phase == .playerTurn else {
            return []
        }

        let slot = context.activeHand
        let hand = context.hand(for: slot)
        guard !hand.isBust, !context.hasStood(for: slot) else {
            return []
        }

        var actions: Set<PlayerAction> = [.hit, .stand]

        let currentBet = context.bet(for: slot)
        if hand.cards.count == 2,
           !context.isDoubled(for: slot),
           context.bankroll >= currentBet {
            actions.insert(.double)
        }

        if slot == .primary,
           !context.hasSplit,
           hand.cards.count == 2,
           hand.cards[0].rank.blackjackValue == hand.cards[1].rank.blackjackValue,
           context.bankroll >= context.primaryBet {
            actions.insert(.split)
        }

        return actions
    }

    func apply(action: PlayerAction, context: RoundContext) -> RoundContext {
        var updated = context
        updated.events = []
        let legalActions = allowedActions(context: updated)
        guard legalActions.contains(action) else {
            updated.allowedActions = legalActions
            return updated
        }

        let slot = updated.activeHand

        switch action {
        case .hit:
            dealCard(to: slot, context: &updated)
            if updated.hand(for: slot).isBust {
                updated.events.append(.bust)
                updated.setHasStood(true, for: slot)
            }

        case .stand:
            updated.setHasStood(true, for: slot)

        case .double:
            let currentBet = updated.bet(for: slot)
            guard updated.bankroll >= currentBet else { break }
            updated.bankroll -= currentBet
            updated.setBet(currentBet * 2, for: slot)
            updated.setIsDoubled(true, for: slot)
            dealCard(to: slot, context: &updated)
            if updated.hand(for: slot).isBust {
                updated.events.append(.bust)
            }
            updated.setHasStood(true, for: slot)

        case .split:
            guard canSplitPrimary(context: updated) else { break }
            updated.bankroll -= updated.primaryBet
            splitPrimaryHand(context: &updated)
        }

        advancePlayerTurn(context: &updated)

        if updated.phase == .playerTurn {
            updated.allowedActions = allowedActions(context: updated)
        } else {
            updated.allowedActions = []
        }

        return updated
    }

    func resolveRound(context: RoundContext) -> RoundResult {
        let dealer = context.dealerHand
        let slots: [PlayerHandSlot] = context.hasSplit ? [.primary, .split] : [.primary]

        var totalCredits = 0
        var resolutions: [HandResolution] = []
        var events: [RoundEvent] = []

        for slot in slots {
            let hand = context.hand(for: slot)
            let bet = context.bet(for: slot)
            let outcome: RoundOutcome
            let payout: Int

            if hand.isBust {
                outcome = .bust
                payout = 0
                events.append(.bust)
            } else if hand.isBlackjack,
                      !context.hasSplit,
                      !dealer.isBlackjack {
                outcome = .blackjack
                payout = (bet * 5) / 2
                events.append(.blackjack)
            } else if dealer.isBust {
                outcome = .playerWin
                payout = bet * 2
                events.append(.playerWin)
            } else if dealer.isBlackjack,
                      !hand.isBlackjack {
                outcome = .dealerWin
                payout = 0
                events.append(.dealerWin)
            } else if hand.bestValue > dealer.bestValue {
                outcome = .playerWin
                payout = bet * 2
                events.append(.playerWin)
            } else if hand.bestValue < dealer.bestValue {
                outcome = .dealerWin
                payout = 0
                events.append(.dealerWin)
            } else {
                outcome = .push
                payout = bet
                events.append(.push)
            }

            totalCredits += payout
            resolutions.append(HandResolution(hand: slot, outcome: outcome, payout: payout))
        }

        let net = totalCredits - context.committedBet
        let overallOutcome: RoundOutcome
        if resolutions.contains(where: { $0.outcome == .blackjack }) {
            overallOutcome = .blackjack
        } else if net > 0 {
            overallOutcome = .playerWin
        } else if net < 0,
                  resolutions.allSatisfy({ $0.outcome == .bust }) {
            overallOutcome = .bust
        } else if net < 0 {
            overallOutcome = .dealerWin
        } else {
            overallOutcome = .push
        }

        if net >= max(200, context.bet * 2) {
            events.append(.winBig)
        }

        return RoundResult(
            netPayout: net,
            outcome: overallOutcome,
            handResolutions: resolutions,
            eventList: events
        )
    }

    private func canSplitPrimary(context: RoundContext) -> Bool {
        let cards = context.playerHand.cards
        return !context.hasSplit
            && cards.count == 2
            && cards[0].rank.blackjackValue == cards[1].rank.blackjackValue
            && context.bankroll >= context.primaryBet
    }

    private func splitPrimaryHand(context: inout RoundContext) {
        let firstCard = context.playerHand.cards[0]
        let secondCard = context.playerHand.cards[1]

        context.playerHand = Hand(cards: [firstCard])
        context.splitHand = Hand(cards: [secondCard])
        context.splitBet = context.primaryBet
        context.activeHand = .primary

        dealCard(to: .primary, context: &context)
        dealCard(to: .split, context: &context)
    }

    private func dealCard(to slot: PlayerHandSlot, context: inout RoundContext) {
        guard let card = context.drawCard() else { return }
        var hand = context.hand(for: slot)
        hand.addCard(card)
        context.set(hand: hand, for: slot)
        context.events.append(.cardDealt)
    }

    private func dealCardToDealer(context: inout RoundContext) {
        guard let card = context.drawCard() else { return }
        context.dealerHand.addCard(card)
        context.events.append(.cardDealt)
    }

    private func advancePlayerTurn(context: inout RoundContext) {
        guard context.phase == .playerTurn else { return }

        let primaryDone = isFinished(slot: .primary, context: context)
        let splitDone = context.hasSplit ? isFinished(slot: .split, context: context) : true

        if context.hasSplit,
           context.activeHand == .primary,
           primaryDone,
           !splitDone {
            context.activeHand = .split
        }

        if primaryDone && splitDone {
            context.phase = .dealerTurn
        }
    }

    private func isFinished(slot: PlayerHandSlot, context: RoundContext) -> Bool {
        let hand = context.hand(for: slot)
        return hand.isBust || context.hasStood(for: slot)
    }

    private func shouldDealerDraw(hand: Hand) -> Bool {
        hand.bestValue < 17
    }
}
