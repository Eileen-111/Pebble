import Foundation

enum OutingReward: Equatable {
    case event(OutingEvent)
    case collectable(OutingCollectable)
}

final class OutingRewardGenerator {
    private let catalog: OutingCatalog
    private let randomUnit: () -> Double
    private let randomIndex: (Int) -> Int

    init(
        catalog: OutingCatalog,
        randomUnit: @escaping () -> Double = { Double.random(in: 0 ..< 1) },
        randomIndex: @escaping (Int) -> Int = { Int.random(in: 0 ..< $0) }
    ) {
        self.catalog = catalog
        self.randomUnit = randomUnit
        self.randomIndex = randomIndex
    }

    func reward(forOutingDuration duration: TimeInterval) -> OutingReward? {
        let rarity = drawRarity(forOutingDuration: duration)
        if rarity == 0 {
            return eventReward()
        }

        let matching = catalog.collectables.filter { $0.rarity == rarity }
        let candidates = matching.isEmpty ? catalog.collectables.filter { $0.rarity == 1 } : matching
        guard !candidates.isEmpty else {
            return eventReward()
        }
        return .collectable(candidates[safeRandomIndex(candidates.count)])
    }

    func eventReward() -> OutingReward? {
        guard !catalog.events.isEmpty else { return nil }
        return .event(catalog.events[safeRandomIndex(catalog.events.count)])
    }

    func rarityProbabilities(forOutingDuration duration: TimeInterval) -> [Int: Double] {
        let minutes = max(0, duration / 60)
        guard minutes >= 25 else {
            return [0: 1, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        }

        let eventT = min(max((minutes - 25) / (360 - 25), 0), 1)
        let eventProbability = 0.5 * (1 - eventT)
        let collectableProbability = 1 - eventProbability
        let rarityT = min(max((minutes - 25) / (480 - 25), 0), 1)
        let startWeights: [Int: Double] = [
            1: 60,
            2: 30,
            3: 7,
            4: 2,
            5: 1
        ]
        let startTotal = startWeights.values.reduce(0, +)
        let targetShares: [Int: Double] = [
            1: 0.15,
            2: 0.22,
            3: 0.30,
            4: 0.20,
            5: 0.13
        ]
        var weights: [Int: Double] = [:]
        for rarity in 1 ... 5 {
            let startShare = startWeights[rarity, default: 0] / startTotal
            let targetShare = targetShares[rarity, default: 0]
            weights[rarity] = exp((1 - rarityT) * log(startShare) + rarityT * log(targetShare))
        }

        let totalWeight = weights.values.reduce(0, +)
        var probabilities: [Int: Double] = [0: eventProbability]
        for rarity in 1 ... 5 {
            probabilities[rarity] = totalWeight > 0 ? collectableProbability * (weights[rarity, default: 0] / totalWeight) : 0
        }
        return probabilities
    }

    func drawRarity(forOutingDuration duration: TimeInterval) -> Int {
        let probabilities = rarityProbabilities(forOutingDuration: duration)
        let roll = min(max(randomUnit(), 0), 0.999999)
        var cumulative = 0.0
        for rarity in 0 ... 5 {
            cumulative += probabilities[rarity, default: 0]
            if roll < cumulative {
                return rarity
            }
        }
        return 5
    }

    private func safeRandomIndex(_ count: Int) -> Int {
        min(max(randomIndex(count), 0), count - 1)
    }
}
