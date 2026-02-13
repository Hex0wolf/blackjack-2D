import Foundation

protocol RandomNumberProviding {
    mutating func nextInt(upperBound: Int) -> Int
}

struct SeededRandom: RandomNumberProviding {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func nextInt(upperBound: Int) -> Int {
        precondition(upperBound > 0, "upperBound must be positive")
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        state &*= 0x2545F4914F6CDD1D
        return Int(state % UInt64(upperBound))
    }
}

extension Array {
    mutating func shuffle<R: RandomNumberProviding>(using generator: inout R) {
        guard count > 1 else { return }
        for index in indices.dropLast() {
            let randomOffset = generator.nextInt(upperBound: count - index)
            let swapIndex = index + randomOffset
            if index != swapIndex {
                swapAt(index, swapIndex)
            }
        }
    }
}
