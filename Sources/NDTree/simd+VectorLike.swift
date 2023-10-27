//
//  simd+VectorLike.swift
//
//
//  Created by li3zhen1 on 10/13/23.
//

#if canImport(simd)

import simd

// extension SIMD2: VectorLike where Scalar: FloatingPoint & CustomDebugStringConvertible {
//    @inlinable public func lengthSquared() -> Scalar {
//        return (self * self).sum() //simd_length_squared(self)
//    }

//    @inlinable public func length() -> Scalar {
//        return lengthSquared().squareRoot()  //simd_length(self)
//    }

//    @inlinable public func distanceSquared(to: Self) -> Scalar {
//        let delta = self-to
//        return (delta * delta).sum()   //simd_length_squared(self - to)
//    }

//    @inlinable public func distance(to: Self) -> Scalar {
//        return distanceSquared(to: to).squareRoot()//simd_length(self - to)
//    }

// }

// extension SIMD3: VectorLike where Scalar: FloatingPoint & CustomDebugStringConvertible {
//    @inlinable public func lengthSquared() -> Scalar {
//        return (self * self).sum() //simd_length_squared(self)
//    }

//    @inlinable public func length() -> Scalar {
//        return lengthSquared().squareRoot()  //simd_length(self)
//    }

//    @inlinable public func distanceSquared(to: Self) -> Scalar {
//        let delta = self-to
//        return (delta * delta).sum()   //simd_length_squared(self - to)
//    }

//    @inlinable public func distance(to: Self) -> Scalar {
//        return distanceSquared(to: to).squareRoot()//simd_length(self - to)
//    }

// }


extension simd_double2: VectorLike {
    @inlinable public func lengthSquared() -> Scalar {
        return simd_length_squared(self)
    }

    @inlinable public func length() -> Scalar {
        return simd_fast_length(self)
    }

    @inlinable public func distanceSquared(to: Self) -> Scalar {
        return simd_length_squared(self - to)
    }

    @inlinable public func distance(to: Self) -> Scalar {
        return simd_fast_distance(self, to)
    }

}



extension simd_float3: VectorLike{
    @inlinable public func lengthSquared() -> Scalar {
        return simd_length_squared(self)
    }

    @inlinable public func length() -> Scalar {
        return simd_length(self)
    }

    @inlinable public func distanceSquared(to: Self) -> Scalar {
        return simd_length_squared(self - to)
    }

    @inlinable public func distance(to: Self) -> Scalar {
        return simd_fast_distance(self, to)
    }

}

public typealias QuadBox = NDBox<SIMD2<Double>>
public typealias OctBox = NDBox<SIMD3<Float>>

#endif
