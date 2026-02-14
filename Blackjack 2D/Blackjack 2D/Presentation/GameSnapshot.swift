import Foundation

struct CardRenderModel: Equatable, Hashable {
    let label: String
    let isFaceDown: Bool

    static let hidden = CardRenderModel(label: "??", isFaceDown: true)

    static func faceUp(_ card: Card) -> CardRenderModel {
        CardRenderModel(label: card.displayName, isFaceDown: false)
    }
}

struct HandRenderModel: Equatable, Hashable {
    let cards: [CardRenderModel]
    let valueText: String
    let isActive: Bool

    var cardsText: String {
        guard !cards.isEmpty else { return "--" }
        return cards.map(\.label).joined(separator: " ")
    }
}

struct TableRenderModel: Equatable {
    let phase: GamePhase
    let dealer: HandRenderModel
    let player: HandRenderModel
    let split: HandRenderModel?
    let activeHand: PlayerHandSlot
    let status: String
    let recentEvents: [RoundEvent]

    static let empty = TableRenderModel(
        phase: .idle,
        dealer: HandRenderModel(cards: [], valueText: "", isActive: false),
        player: HandRenderModel(cards: [], valueText: "", isActive: true),
        split: nil,
        activeHand: .primary,
        status: "Ready",
        recentEvents: []
    )
}

struct GameSnapshot: Equatable {
    let table: TableRenderModel

    var phase: GamePhase { table.phase }
    var dealerCards: String { table.dealer.cardsText }
    var dealerValue: String { table.dealer.valueText }
    var playerCards: String { table.player.cardsText }
    var playerValue: String { table.player.valueText }
    var splitCards: String? { table.split?.cardsText }
    var splitValue: String? { table.split?.valueText }
    var activeHand: PlayerHandSlot { table.activeHand }
    var status: String { table.status }
    var recentEvents: [RoundEvent] { table.recentEvents }

    static let empty = GameSnapshot(
        table: .empty
    )

    init(table: TableRenderModel) {
        self.table = table
    }

    init(
        phase: GamePhase,
        dealerCards: String,
        dealerValue: String,
        playerCards: String,
        playerValue: String,
        splitCards: String?,
        splitValue: String?,
        activeHand: PlayerHandSlot,
        status: String,
        recentEvents: [RoundEvent]
    ) {
        self.table = TableRenderModel(
            phase: phase,
            dealer: HandRenderModel(
                cards: Self.cardsFromLegacyString(dealerCards),
                valueText: dealerValue,
                isActive: false
            ),
            player: HandRenderModel(
                cards: Self.cardsFromLegacyString(playerCards),
                valueText: playerValue,
                isActive: activeHand == .primary
            ),
            split: splitCards.map {
                HandRenderModel(
                    cards: Self.cardsFromLegacyString($0),
                    valueText: splitValue ?? "",
                    isActive: activeHand == .split
                )
            },
            activeHand: activeHand,
            status: status,
            recentEvents: recentEvents
        )
    }

    private static func cardsFromLegacyString(_ text: String) -> [CardRenderModel] {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, normalized != "--" else { return [] }

        return normalized
            .split(separator: " ")
            .map { token in
                let value = String(token)
                return value == "??"
                    ? .hidden
                    : CardRenderModel(label: value, isFaceDown: false)
            }
    }
}
