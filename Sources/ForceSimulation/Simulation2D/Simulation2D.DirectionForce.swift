//
//  PositionForce.swift
//
//
//  Created by li3zhen1 on 10/1/23.
//

#if canImport(simd)

import simd



extension Simulation2D {

    /// A force that moves nodes to a target position.
    /// Center force is relatively fast, the complexity is `O(n)`,
    /// where `n` is the number of nodes.
    /// See [Position Force - D3](https://d3js.org/d3-force/position).
    final public class DirectionForce2D: ForceLike
    where NodeID: Hashable {

        public typealias V = simd_double2

        public enum Direction {
            case x
            case y
            case entryOfVector(Int)
        }
        public enum Strength {
            case constant(V.Scalar)
            case varied((NodeID) -> V.Scalar)
        }

        public enum TargetOnDirection {
            case constant(V.Scalar)
            case varied((NodeID) -> V.Scalar)
        }

        public var strength: Strength
        public var direction: Int
        public var calculatedStrength: [V.Scalar] = []
        public var targetOnDirection: TargetOnDirection
        public var calculatedTargetOnDirection: [V.Scalar] = []

        internal init(
            direction: Direction, targetOnDirection: TargetOnDirection,
            strength: Strength = .constant(1.0)
        ) {

            self.strength = strength
            self.direction = direction.lane
            self.targetOnDirection = targetOnDirection
        }

        weak var simulation: Simulation2D<NodeID>? {
            didSet {
                guard let sim = self.simulation else { return }
                self.calculatedStrength = strength.calculated(for: sim)
                self.calculatedTargetOnDirection = targetOnDirection.calculated(for: sim)
            }
        }

        public func apply() {
            guard let sim = self.simulation else { return }
            let alpha = sim.alpha
            let lane = self.direction
            for i in sim.nodePositions.indices {
                sim.nodeVelocities[i][lane] +=
                    (self.calculatedTargetOnDirection[i] - sim.nodePositions[i][lane])
                    * self.calculatedStrength[i] * alpha
            }
        }
    }

    /// Create a direction force that moves nodes to a target position.
    /// Center force is relatively fast, the complexity is `O(n)`,
    /// where `n` is the number of nodes.
    /// See [Position Force - D3](https://d3js.org/d3-force/position).
    @discardableResult
    public func createPositionForce(
        direction: DirectionForce2D.Direction,
        targetOnDirection: DirectionForce2D.TargetOnDirection,
        strength: DirectionForce2D.Strength = .constant(1.0)
    ) -> DirectionForce2D {
        let force = DirectionForce2D(
            direction: direction,
            targetOnDirection: targetOnDirection,
            strength: strength
        )
        force.simulation = self
        self.forces.append(force)
        return force
    }
}

extension Simulation2D.DirectionForce2D.Strength {
    public func calculated(for simulation: Simulation2D<NodeID>) -> [Double] {
        switch self {
        case .constant(let value):
            return Array(repeating: value, count: simulation.nodeIds.count)
        case .varied(let getter):
            return simulation.nodeIds.map(getter)
        }
    }
}

extension Simulation2D.DirectionForce2D.TargetOnDirection {
    public func calculated(for simulation: Simulation2D<NodeID>) -> [Double] {
        switch self {
        case .constant(let value):
            return Array(repeating: value, count: simulation.nodeIds.count)
        case .varied(let getter):
            return simulation.nodeIds.map(getter)
        }
    }
}

extension Simulation2D.DirectionForce2D.Direction {
    @inlinable var lane: Int {
        switch self {
        case .x: return 0
        case .y: return 1
        case .entryOfVector(let i): return i
        }
    }
}
#endif