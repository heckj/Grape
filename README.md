<p align="center">
  <img alt="grape-icon" src="https://github.com/li3zhen1/Grape/assets/45376537/4ab08ea1-22e6-4fe8-ab2b-99ae325b46a6" height="96">
  <h1 align="center">Grape</h1>

</p>

<p align="center">
  <img src="https://github.com/li3zhen1/Grape/actions/workflows/swift.yml/badge.svg" alt="swift workflow">
  <a href="https://swiftpackageindex.com/li3zhen1/Grape"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fli3zhen1%2FGrape%2Fbadge%3Ftype%3Dswift-versions" alt="swift package index"></a>
  <a href="https://swiftpackageindex.com/li3zhen1/Grape"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fli3zhen1%2FGrape%2Fbadge%3Ftype%3Dplatforms" alt="swift package index"></a>

</p>

<p align="center">A Swift library for force simulation and graph visualization.
  <img width="712" alt="ForceDirected" src="https://github.com/li3zhen1/Grape/assets/45376537/1cbc938e-55a8-438e-b20b-3e52577ac30a">
</p>






## Examples

### Force Directed Graph
This is a force directed graph visualizing the data from [Force Directed Graph Component](https://observablehq.com/@d3/force-directed-graph-component), iterating at 120FPS. Take a closer look at the animation:



https://github.com/li3zhen1/Grape/assets/45376537/d80dc797-1980-4755-85b9-18ee26e2a7ff



Source code: [ContentView.swift](https://github.com/li3zhen1/Grape/blob/main/Examples/ForceDirectedGraphExample/ForceDirectedGraphExample/ContentView.swift). 

<br/>

### Lattice Simulation

This is a 36x36 force directed lattice like [Force Directed Lattice](https://observablehq.com/@d3/force-directed-lattice):



https://github.com/li3zhen1/Grape/assets/45376537/5b76fddc-dd5c-4d35-bced-29c01269dd2b



Source code: [ForceDirectedLatticeView.swift](https://github.com/li3zhen1/Grape/blob/main/Examples/ForceDirectedGraphExample/ForceDirectedGraphExample/ForceDirectedLatticeView.swift)


<br/>

### Force Directed Graph in visionOS

This is the same graph as the first example, rendered in `RealityView`:



https://github.com/li3zhen1/Grape/assets/45376537/4585471e-2339-4aee-8f39-0c11fdfb6901



Source code: [ForceDirectedGraph3D/ContentView.swift](https://github.com/li3zhen1/Grape/blob/main/Examples/ForceDirectedGraph3D/ForceDirectedGraph3D/ContentView.swift)

<br/>


## Usage

Grape provides 2 kinds of classes, `NDTree` and `Simulation`. 
- `NDTree` is a KD-Tree data structure, which is used to accelerate the force simulation with [Barnes-Hut Approximation](https://jheer.github.io/barnes-hut/).
- `Simulation` is a force simulation class, that enables you to create any dimensional simulation with velocity Verlet integration.

### Basic

The basic concepts of simulations and forces can be found here: [Force simulations - D3](https://d3js.org/d3-force/simulation). You can simply create 2D or 3D simulations by using `Simulation2D` or `Simulation3D`:

```swift
import simd
import ForceSimulation

struct Node: Identifiable { ... }

let nodeIds: [Node.ID] = ... 
let links: [(Node.ID, Node.ID)] = ... 

let sim = Simulation2D(nodeIds: nodeIds, alphaDecay: 0.01)
sim.createManyBodyForce(strength: -12)
sim.createLinkForce(links)
sim.createCenterForce(center: [0, 0], strength: 0.4)
sim.createCollideForce(radius: .constant(3))

/// Force is ready to start! run `tick` to iterate the simulation.

for i in 0..<120 {
    sim.tick()
    let positions = sim.nodePositions
    /// Do something with the positions.
}

```

See [Example](https://github.com/li3zhen1/Grape/tree/main/Examples/ForceDirectedGraphExample) for more details. 

<br/>

### Advanced

Grape provides a set of generic based types that works with any SIMD-like data structures. To integrate Grape into platforms where `import simd` isn't supported, or higher dimensions, you need to create a struct conforming to the `VectorLike` protocol. For ease of use, it's also recommended to add some type aliases. Here’s how you can do it:

```swift
/// All required implementations should have same semantics
/// as the SIMD protocol provided in Foundation.
struct SuperCool4DVector: VectorLike { ... }

protocol HyperoctreeDelegate: NDTreeDelegate where V == SuperCool4DVector {}
typealias HyperoctBox = NDBox<SuperCool4DVector>
typealias Hyperoctree<TD: HyperoctreeDelegate> = NDTree<SuperCool4DVector, TD>

typealias Simulation4D<NodeID: Hashable> = SimulationKD<NodeID, Vector4d>
```

> [!IMPORTANT]  
> When using generic based types, you ***pay for dynamic dispatch***, in terms of performance. Although their implementations are basically the same, it's recommended to use `Simulation2D` or `Simulation3D` whenever possible.


<br/>


## Roadmap

|   | 2D simd | ND simd | Metal |
| --- | --- | --- | --- |
| **NdTree** | ✅ | ✅ |  |
| **Simulation** | ✅ | ✅ |  |
| &emsp;LinkForce | ✅ | ✅ |  |
| &emsp;ManyBodyForce | ✅ | ✅ |  |
| &emsp;CenterForce | ✅ | ✅ |  |
| &emsp;CollideForce | ✅ | ✅ |  |
| &emsp;PositionForce | ✅ | ✅ |  |
| &emsp;RadialForce | ✅ | ✅ |  |
| **SwiftUI View** | 🚧 |  |  |


<br/>

## Performance

Grape uses simd to calculate position and velocity. Currently it takes ~0.034 seconds to iterate 120 times over the example graph(2D). (77 vertices, 254 edges, with manybody, center, collide and link forces. Release build on a M1 Max, tested with command `swift test -c release`)

For 3D simulation, it takes ~0.052 seconds for the same graph and same configs.


<br/>

## Credits

This library has been greatly influenced by the outstanding work done by [D3.js (Data-Driven Documents)](https://d3js.org).
