import Foundation

protocol ShoeProviding {
    @MainActor func makeShoe() -> [Card]
}

struct RandomShoeProvider: ShoeProviding {
    func makeShoe() -> [Card] {
        DeckFactory.makeShuffledShoe()
    }
}
