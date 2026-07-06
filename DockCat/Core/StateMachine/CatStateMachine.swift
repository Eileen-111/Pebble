import CoreGraphics
import Foundation

final class CatStateMachine {
    typealias RandomDuration = (ClosedRange<TimeInterval>) -> TimeInterval
    typealias RandomLongDurationState = () -> LongDurationState
    typealias RandomTransitionInsertion = () -> Bool

    private(set) var state: CatState
    private(set) var position: CGPoint
    private let entranceProvider: () -> CGPoint
    private let randomDuration: RandomDuration
    private let randomLongDurationState: RandomLongDurationState
    private let randomTransitionInsertion: RandomTransitionInsertion
    private var walkingDurationRange: ClosedRange<TimeInterval>
    private var restingDurationRange: ClosedRange<TimeInterval>

    var onTransition: ((CatState, CatState) -> Void)?
    var onDurationScheduled: ((CatState, TimeInterval) -> Void)?
    var onReminderDeferred: ((ReminderType) -> Void)?

    init(
        initialState: CatState = .resting,
        initialPosition: CGPoint = .zero,
        entranceProvider: @escaping () -> CGPoint,
        walkingDurationRange: ClosedRange<TimeInterval> = 2 * 60 ... 5 * 60,
        restingDurationRange: ClosedRange<TimeInterval> = 2 * 60 ... 5 * 60,
        randomDuration: @escaping RandomDuration = { range in
            let lower = Int((range.lowerBound / 60).rounded(.up))
            let upper = Int((range.upperBound / 60).rounded(.down))
            guard lower <= upper else { return range.lowerBound }
            return TimeInterval(Int.random(in: lower ... upper) * 60)
        },
        randomLongDurationState: @escaping RandomLongDurationState = {
            LongDurationState.allCases.randomElement() ?? .resting
        },
        randomTransitionInsertion: @escaping RandomTransitionInsertion = {
            Bool.random()
        }
    ) {
        self.state = initialState
        self.position = initialPosition
        self.entranceProvider = entranceProvider
        self.randomDuration = randomDuration
        self.randomLongDurationState = randomLongDurationState
        self.randomTransitionInsertion = randomTransitionInsertion
        self.walkingDurationRange = walkingDurationRange
        self.restingDurationRange = restingDurationRange
    }

    func updateParameters(walkingDurationRange: ClosedRange<TimeInterval>, restingDurationRange: ClosedRange<TimeInterval>) {
        self.walkingDurationRange = walkingDurationRange
        self.restingDurationRange = restingDurationRange
    }

    func start() {
        position = entranceProvider()
        enterTransitioning()
    }

    func enterRandomLongDurationState() {
        switch randomLongDurationState() {
        case .walking:
            transition(to: .walking)
            scheduleCurrentState()
        case .resting:
            transition(to: .resting)
            scheduleCurrentState()
        }
    }

    func finishTransitioning() {
        guard case .transitioning = state else { return }
        enterRandomLongDurationState()
    }

    func finishScheduledState(_ scheduledState: CatState) {
        guard state == scheduledState else { return }
        switch scheduledState {
        case .transitioning:
            finishTransitioning()
        case .resting, .walking:
            enterRandomLongDurationStateWithOptionalTransition()
        default:
            return
        }
    }

    func beginDrag() {
        guard state.canBeginDrag else { return }
        transition(to: .dragged)
    }

    func updateDragPosition(_ point: CGPoint) {
        guard case .dragged = state else { return }
        position = point
    }

    func updateLongDurationPosition(_ point: CGPoint) {
        guard state.isLongDuration else { return }
        position = point
    }

    func updateVisiblePosition(_ point: CGPoint) {
        switch state {
        case .transitioning, .walking, .resting, .dragged, .dialogue,
             .outing(.asking), .outing(.confirmingDeparture), .outing(.returned):
            position = point
        default:
            return
        }
    }

    func updateOutingWalkPosition(_ point: CGPoint) {
        switch state {
        case .outing(.leaving), .outing(.returning):
            position = point
        default:
            return
        }
    }

    func endDrag(at point: CGPoint) {
        guard case .dragged = state else { return }
        position = point
        enterRandomLongDurationStateWithOptionalTransition()
    }

    func requestReminder(_ type: ReminderType) -> Bool {
        guard state.isLongDuration else {
            onReminderDeferred?(type)
            return false
        }
        transition(to: .dialogue(type))
        return true
    }

    func finishReminder() {
        guard case .dialogue = state else { return }
        enterRandomLongDurationState()
    }

    func beginOutingPrompt() {
        guard !isOuting else { return }
        transition(to: .outing(.asking))
    }

    func confirmOuting() {
        guard case .outing(.asking) = state else { return }
        transition(to: .outing(.confirmingDeparture))
    }

    func departOuting() {
        guard case .outing(.confirmingDeparture) = state else { return }
        transition(to: .outing(.leaving))
    }

    func restoreOutingAway() {
        transition(to: .outing(.away))
    }

    func markAway() {
        guard case .outing(.leaving) = state else { return }
        transition(to: .outing(.away))
    }

    func returnFromOuting() {
        guard case .outing = state else { return }
        position = entranceProvider()
        transition(to: .outing(.returning))
    }

    func finishReturnWalk() {
        guard case .outing(.returning) = state else { return }
        transition(to: .outing(.returned))
    }

    func welcomeBack() {
        guard case .outing(.returned) = state else { return }
        enterRandomLongDurationStateWithOptionalTransition()
    }

    private var isOuting: Bool {
        if case .outing = state { return true }
        return false
    }

    private func scheduleCurrentState() {
        let duration: TimeInterval
        switch state {
        case .walking:
            duration = randomDuration(walkingDurationRange)
        case .resting:
            duration = randomDuration(restingDurationRange)
        default:
            return
        }
        onDurationScheduled?(state, duration)
    }

    private func enterRandomLongDurationStateWithOptionalTransition() {
        if randomTransitionInsertion() {
            enterTransitioning()
        } else {
            enterRandomLongDurationState()
        }
    }

    private func enterTransitioning() {
        transition(to: .transitioning)
        onDurationScheduled?(.transitioning, 2.0)
    }

    private func transition(to newState: CatState) {
        let oldState = state
        state = newState
        DockCatLog.state.debug("State transition \(oldState.description) -> \(newState.description)")
        onTransition?(oldState, newState)
    }
}
