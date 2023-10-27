//
//  File.swift
//
//
//  Created by li3zhen1 on 10/17/23.
//
import NDTree

struct MaxRadiusTreeDelegate<NodeID, V>: NDTreeDelegate&KDTreeDelegate where NodeID: Hashable, V: VectorLike {

    public var maxNodeRadius: V.Scalar

    @usableFromInline var radiusProvider: (NodeID) -> V.Scalar

    mutating func didAddNode(_ nodeId: NodeID, at position: V) {
        let p = radiusProvider(nodeId)
        maxNodeRadius = max(maxNodeRadius, p)
    }

    mutating func didRemoveNode(_ nodeId: NodeID, at position: V) {
        if radiusProvider(nodeId) >= maxNodeRadius {
            // 🤯 for Collide force, set to 0 is fine
            // Otherwise you need to traverse the delegate again
            maxNodeRadius = 0
        }
    }

    func copy() -> MaxRadiusTreeDelegate<NodeID, V> {
        return Self(maxNodeRadius: maxNodeRadius, radiusProvider: radiusProvider)
    }

    func spawn() -> MaxRadiusTreeDelegate<NodeID, V> {
        return Self(radiusProvider: radiusProvider)
    }

    init(maxNodeRadius: V.Scalar = 0, radiusProvider: @escaping (NodeID) -> V.Scalar) {
        self.maxNodeRadius = maxNodeRadius
        self.radiusProvider = radiusProvider
    }

}

extension SimulationKD {
    /// A force that prevents nodes from overlapping.
    /// This is a very expensive force, the complexity is `O(n log(n))`,
    /// where `n` is the number of nodes.
    /// See [Collide Force - D3](https://d3js.org/d3-force/collide).
    public final class CollideForce: ForceLike
    where NodeID: Hashable, V: VectorLike, V.Scalar : SimulatableFloatingPoint {

        weak var simulation: SimulationKD? {
            didSet {
                guard let sim = simulation else { return }
                self.calculatedRadius = radius.calculated(for: sim)
            }
        }

        public enum CollideRadius {
            case constant(V.Scalar)
            case varied((NodeID) -> V.Scalar)
        }
        public var radius: CollideRadius
        var calculatedRadius: [V.Scalar] = []

        public let iterationsPerTick: UInt
        public var strength: V.Scalar

        internal init(
            radius: CollideRadius,
            strength: V.Scalar = 1.0,
            iterationsPerTick: UInt = 1
        ) {
            self.radius = radius
            self.iterationsPerTick = iterationsPerTick
            self.strength = strength
        }

        public func apply() {
            guard let sim = self.simulation else { return }
            let alpha = sim.alpha

            for _ in 0..<iterationsPerTick {

                let coveringBox = NDBox<V>.cover(of: sim.nodePositions)

                let clusterDistance: V.Scalar = V.Scalar(Int(0.00001))

                let tree = NDTree<V, MaxRadiusTreeDelegate<Int, V>>(
                    box: coveringBox, clusterDistance: clusterDistance
                ) {
                    return switch self.radius {
                    case .constant(let m):
                        MaxRadiusTreeDelegate<Int, V> { _ in m }
                    case .varied(_):
                        MaxRadiusTreeDelegate<Int, V> { index in
                            self.calculatedRadius[index]
                        }
                    }
                }

                for i in sim.nodePositions.indices {
                    tree.add(i, at: sim.nodePositions[i])
                }

                for i in sim.nodePositions.indices {
                    let iOriginalPosition = sim.nodePositions[i]
                    let iOriginalVelocity = sim.nodeVelocities[i]
                    let iR = self.calculatedRadius[i]
                    let iR2 = iR * iR
                    let iPosition = iOriginalPosition + iOriginalVelocity

                    tree.visit { t in

                        let maxRadiusOfQuad = t.delegate.maxNodeRadius
                        let deltaR = maxRadiusOfQuad + iR

                        if t.nodePosition != nil {
                            for j in t.nodeIndices {
                                //                            print("\(i)<=>\(j)")
                                // is leaf, make sure every collision happens once.
                                guard j > i else { continue }

                                let jR = self.calculatedRadius[j]
                                let jOriginalPosition = sim.nodePositions[j]
                                let jOriginalVelocity = sim.nodeVelocities[j]
                                var deltaPosition =
                                    iPosition - (jOriginalPosition + jOriginalVelocity)
                                let l = deltaPosition.lengthSquared()

                                let deltaR = iR + jR
                                if l < deltaR * deltaR {

                                    var l = deltaPosition.jiggled().length()
                                    l = (deltaR - l) / l * self.strength

                                    let jR2 = jR * jR

                                    let k = jR2 / (iR2 + jR2)

                                    deltaPosition *= l

                                    sim.nodeVelocities[i] += deltaPosition * k
                                    sim.nodeVelocities[j] -= deltaPosition * (1 - k)
                                }
                            }
                            return false
                        }

                        for laneIndex in t.box.p0.indices {
                            let _v = t.box.p0[laneIndex]
                            if _v > iPosition[laneIndex] + deltaR /* True if no overlap */ {
                                return false
                            }
                        }

                        for laneIndex in t.box.p1.indices {
                            let _v = t.box.p1[laneIndex]
                            if _v < iPosition[laneIndex] - deltaR /* True if no overlap */ {
                                return false
                            }
                        }
                        return true

                        // return
                        //     !(t.quad.x0 > iPosition.x + deltaR /* True if no overlap */
                        //     || t.quad.x1 < iPosition.x - deltaR
                        //     || t.quad.y0 > iPosition.y + deltaR
                        //     || t.quad.y1 < iPosition.y - deltaR)
                    }
                }
            }
        }

    }

    /// Create a collide force that prevents nodes from overlapping.
    /// This is a very expensive force, the complexity is `O(n log(n))`,
    /// where `n` is the number of nodes.
    /// See [Collide Force - D3](https://d3js.org/d3-force/collide).
    /// - Parameters:
    ///   - radius: The radius of the force.
    ///   - strength: The strength of the force.
    ///   - iterationsPerTick: The number of iterations per tick.
    @discardableResult
    public func createCollideForce(
        radius: CollideForce.CollideRadius = .constant(3.0),
        strength: V.Scalar = 1.0,
        iterationsPerTick: UInt = 1
    ) -> CollideForce {
        let f = CollideForce(
            radius: radius,
            strength: strength,
            iterationsPerTick: iterationsPerTick
        )
        f.simulation = self
        self.forces.append(f)
        return f
    }

}

extension SimulationKD.CollideForce.CollideRadius {
    public func calculated(for simulation: SimulationKD) -> [V.Scalar] {
        switch self {
        case .constant(let r):
            return Array(repeating: r, count: simulation.nodePositions.count)
        case .varied(let radiusProvider):
            return simulation.nodeIds.map { radiusProvider($0) }
        }
    }
}
