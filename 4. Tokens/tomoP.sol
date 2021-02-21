pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


library EllipticCurve {

    /// @dev Modular euclidean inverse of a number (mod p).
    /// @param _x The number
    /// @param _pp The modulus
    /// @return q such that x*q = 1 (mod _pp)
    function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
        if (_x == 0 || _x == _pp || _pp == 0) {
            revert("Invalid number");
        }
        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = _pp;
        uint256 newR = _x;
        uint256 t;
        while (newR != 0) {
            t = r / newR;
            (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
            (r, newR) = (newR, r - t * newR );
        }

        return q;
    }

    /// @dev Modular exponentiation, b^e % _pp.
    /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
    /// @param _base base
    /// @param _exp exponent
    /// @param _pp modulus
    /// @return r such that r = b**e (mod _pp)
    function expMod(uint256 _base, uint256 _exp, uint256 _pp) internal pure returns (uint256) {
        if (_base == 0)
            return 0;
        if (_exp == 0)
            return 1;
        if (_pp == 0)
            revert("Modulus is zero");
        uint256 r = 1;
        uint256 bit = 2 ** 255;

        assembly {
            for { } gt(bit, 0) { }{
                r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, bit)))), _pp)
                r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), _pp)
                r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), _pp)
                r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), _pp)
                bit := div(bit, 16)
            }
        }

        return r;
    }

    /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
    /// @param _x coordinate x
    /// @param _y coordinate y
    /// @param _z coordinate z
    /// @param _pp the modulus
    /// @return (x', y') affine coordinates
    function toAffine(
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _pp)
    internal pure returns (uint256, uint256)
    {
        uint256 zInv = invMod(_z, _pp);
        uint256 zInv2 = mulmod(zInv, zInv, _pp);
        uint256 x2 = mulmod(_x, zInv2, _pp);
        uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

        return (x2, y2);
    }

    /// @dev Derives the y coordinate from a compressed-format point x.
    /// @param _prefix parity byte (0x02 even, 0x03 odd)
    /// @param _x coordinate x
    /// @param _aa constant of curve
    /// @param _bb constant of curve
    /// @param _pp the modulus
    /// @return y coordinate y
    function deriveY(
        uint8 _prefix,
        uint256 _x,
        uint256 _aa,
        uint256 _bb,
        uint256 _pp)
    internal pure returns (uint256)
    {
        // x^3 + ax + b
        uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, _pp), _pp), addmod(mulmod(_x, _aa, _pp), _bb, _pp), _pp);
        y2 = expMod(y2, (_pp + 1) / 4, _pp);
        // uint256 cmp = yBit ^ y_ & 1;
        uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : _pp - y2;

        return y;
    }

    /// @dev Check whether point (x,y) is on curve defined by a, b, and _pp.
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _aa constant of curve
    /// @param _bb constant of curve
    /// @param _pp the modulus
    /// @return true if x,y in the curve, false else
    function isOnCurve(
        uint _x,
        uint _y,
        uint _aa,
        uint _bb,
        uint _pp)
    internal pure returns (bool)
    {
        if (0 == _x || _x == _pp || 0 == _y || _y == _pp) {
            return false;
        }
        // y^2
        uint lhs = mulmod(_y, _y, _pp);
        // x^3
        uint rhs = mulmod(mulmod(_x, _x, _pp), _x, _pp);
        if (_aa != 0) {
            // x^3 + a*x
            rhs = addmod(rhs, mulmod(_x, _aa, _pp), _pp);
        }
        if (_bb != 0) {
            // x^3 + a*x + b
            rhs = addmod(rhs, _bb, _pp);
        }

        return lhs == rhs;
    }

    /// @dev Calculate inverse (x, -y) of point (x, y).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _pp the modulus
    /// @return (x, -y)
    function ecInv(
        uint256 _x,
        uint256 _y,
        uint256 _pp)
    internal pure returns (uint256, uint256)
    {
        return (_x, (_pp - _y) % _pp);
    }

    /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @param _aa constant of the curve
    /// @param _pp the modulus
    /// @return (qx, qy) = P1+P2 in affine coordinates
    function ecAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2,
        uint256 _aa,
        uint256 _pp)
    internal pure returns(uint256, uint256)
    {
        uint x = 0;
        uint y = 0;
        uint z = 0;
        // Double if x1==x2 else add
        if (_x1==_x2) {
            (x, y, z) = jacDouble(
                _x1,
                _y1,
                1,
                _aa,
                _pp);
        } else {
            (x, y, z) = jacAdd(
                _x1,
                _y1,
                1,
                _x2,
                _y2,
                1,
                _pp);
        }
        // Get back to affine
        return toAffine(
            x,
            y,
            z,
            _pp);
    }

    /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @param _aa constant of the curve
    /// @param _pp the modulus
    /// @return (qx, qy) = P1-P2 in affine coordinates
    function ecSub(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2,
        uint256 _aa,
        uint256 _pp)
    internal pure returns(uint256, uint256)
    {
        // invert square
        (uint256 x, uint256 y) = ecInv(_x2, _y2, _pp);
        // P1-square
        return ecAdd(
            _x1,
            _y1,
            x,
            y,
            _aa,
            _pp);
    }

    /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
    /// @param _k scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _aa constant of the curve
    /// @param _pp the modulus
    /// @return (qx, qy) = d*P in affine coordinates
    function ecMul(
        uint256 _k,
        uint256 _x,
        uint256 _y,
        uint256 _aa,
        uint256 _pp)
    internal pure returns(uint256, uint256)
    {
        // Jacobian multiplication
        (uint256 x1, uint256 y1, uint256 z1) = jacMul(
            _k,
            _x,
            _y,
            1,
            _aa,
            _pp);
        // Get back to affine
        return toAffine(
            x1,
            y1,
            z1,
            _pp);
    }

    /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _z1 coordinate z of P1
    /// @param _x2 coordinate x of square
    /// @param _y2 coordinate y of square
    /// @param _z2 coordinate z of square
    /// @param _pp the modulus
    /// @return (qx, qy, qz) P1+square in Jacobian
    function jacAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _z1,
        uint256 _x2,
        uint256 _y2,
        uint256 _z2,
        uint256 _pp)
    internal pure returns (uint256, uint256, uint256)
    {
        if ((_x1==0)&&(_y1==0))
            return (_x2, _y2, _z2);
        if ((_x2==0)&&(_y2==0))
            return (_x1, _y1, _z1);
        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5

        uint[4] memory zs; // z1^2, z1^3, z2^2, z2^3
        zs[0] = mulmod(_z1, _z1, _pp);
        zs[1] = mulmod(_z1, zs[0], _pp);
        zs[2] = mulmod(_z2, _z2, _pp);
        zs[3] = mulmod(_z2, zs[2], _pp);

        // u1, s1, u2, s2
        zs = [
        mulmod(_x1, zs[2], _pp),
        mulmod(_y1, zs[3], _pp),
        mulmod(_x2, zs[0], _pp),
        mulmod(_y2, zs[1], _pp)
        ];
        if (zs[0] == zs[2]) {
            if (zs[1] != zs[3])
                revert("Wrong data");
            else {
                revert("Use double instead");
            }
        }
        uint[4] memory hr;
        //h
        hr[0] = addmod(zs[2], _pp - zs[0], _pp);
        //r
        hr[1] = addmod(zs[3], _pp - zs[1], _pp);
        //h^2
        hr[2] = mulmod(hr[0], hr[0], _pp);
        // h^3
        hr[3] = mulmod(hr[2], hr[0], _pp);
        // qx = -h^3  -2u1h^2+r^2
        uint256 qx = addmod(mulmod(hr[1], hr[1], _pp), _pp - hr[3], _pp);
        qx = addmod(qx, _pp - mulmod(2, mulmod(zs[0], hr[2], _pp), _pp), _pp);
        // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
        uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp), _pp);
        qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
        // qz = h*z1*z2
        uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
        return(qx, qy, qz);
    }

    /// @dev Doubles a points (x, y, z).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @param _pp the modulus
    /// @param _aa the a scalar in the curve equation
    /// @return (qx, qy, qz) 2P in Jacobian
    function jacDouble(
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _aa,
        uint256 _pp)
    internal pure returns (uint256, uint256, uint256)
    {
        if (_z == 0)
            return (_x, _y, _z);
        uint256[3] memory square;
        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
        square[0] = mulmod(_x, _x, _pp); //x1^2
        square[1] = mulmod(_y, _y, _pp); //y1^2
        square[2] = mulmod(_z, _z, _pp); //z1^2

        // s
        uint s = mulmod(4, mulmod(_x, square[1], _pp), _pp);
        // m
        uint m = addmod(mulmod(3, square[0], _pp), mulmod(_aa, mulmod(square[2], square[2], _pp), _pp), _pp);
        // qx
        uint256 qx = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
        // qy = -8*y1^4 + M(S-T)
        uint256 qy = addmod(mulmod(m, addmod(s, _pp - qx, _pp), _pp), _pp - mulmod(8, mulmod(square[1], square[1], _pp), _pp), _pp);
        // qz = 2*y1*z1
        uint256 qz = mulmod(2, mulmod(_y, _z, _pp), _pp);

        return (qx, qy, qz);
    }

    /// @dev Multiply point (x, y, z) times d.
    /// @param _d scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @param _aa constant of curve
    /// @param _pp the modulus
    /// @return (qx, qy, qz) d*P1 in Jacobian
    function jacMul(
        uint256 _d,
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _aa,
        uint256 _pp)
    internal pure returns (uint256, uint256, uint256)
    {
        uint256 remaining = _d;
        uint256[3] memory point;
        point[0] = _x;
        point[1] = _y;
        point[2] = _z;
        uint256 qx = 0;
        uint256 qy = 0;
        uint256 qz = 1;

        if (_d == 0) {
            return (qx, qy, qz);
        }
        // Double and add algorithm
        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (qx, qy, qz) = jacAdd(
                    qx,
                    qy,
                    qz,
                    point[0],
                    point[1],
                    point[2],
                    _pp);
            }
            remaining = remaining / 2;
            (point[0], point[1], point[2]) = jacDouble(
                point[0],
                point[1],
                point[2],
                _aa,
                _pp);
        }
        return (qx, qy, qz);
    }
}

library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Secp256k1 {
    using SafeMath for uint256;

    // TODO separate curve from crypto primitives?
    uint256 constant n = 0x30644E72E131A029B85045B68181585D97816A916871CA8D3C208C16D87CFD47;
    // Field size
    uint constant pp = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    // Base point (generator) G
    uint constant Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint constant Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;

    uint constant Hx = 0x50929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0;
    uint constant Hy = 0x31d3c6863973926e049e637cb1b5f40a36dac28af1766968c30c2313f3a38904;
    uint256 constant AA = 0;
    uint256 constant BB = 7;

    // Order of G
    uint constant nn = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    // Cofactor
    // uint constant hh = 1;

    // Maximum value of s
    uint constant lowSmax = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    // For later
    // uint constant lambda = "0x5363ad4cc05c30e0a5261c028812645a122e22ea20816678df02967c1b23bd72";
    // uint constant beta = "0x7ae96a2b657c07106e64479eac3434e99cf0497512f58995c1396c28719501ee";

    /// @dev See Curve.onCurve
    function onCurve(uint[2] memory P) internal pure returns (bool) {
        uint p = pp;
        if (0 == P[0] || P[0] == p || 0 == P[1] || P[1] == p)
            return false;
        uint LHS = mulmod(P[1], P[1], p);
        uint RHS = addmod(mulmod(mulmod(P[0], P[0], p), P[0], p), 7, p);
        return LHS == RHS;
    }

    function onCurveXY(uint X, uint Y) internal pure returns (bool) {
        uint[2] memory P;
        P[0] = X;
        P[1] = Y;
        return onCurve(P);
    }

    function onCurveCompress(uint8 yBit, uint x) internal pure returns(bool) {
        uint[2] memory _decompressed = decompress(yBit, x);
        (uint8 _yBit, uint _x) = compress(_decompressed);
        return (_yBit == yBit && _x == x);
    }

    /// @dev See Curve.isPubKey
    function isPubKey(uint[2] memory P) internal pure returns (bool isPK) {
        isPK = onCurve(P);
    }

    /// @dev See Curve.validateSignature
    function validateSignature(uint message, uint[2] memory rs, uint[2] memory Q) internal pure returns (bool) {
        uint p = pp;
        if(rs[0] == 0 || rs[0] >= n || rs[1] == 0 || rs[1] > lowSmax)
            return false;
        if (!isPubKey(Q))
            return false;

        uint sInv = EllipticCurve.invMod(rs[1], p);
        uint[3] memory u1G = _mul(mulmod(message, sInv, n), [Gx, Gy]);
        uint[3] memory u2Q = _mul(mulmod(rs[0], sInv, n), Q);
        uint[3] memory P;
        (P[0], P[1], P[2]) = EllipticCurve.jacAdd(u1G[0], u1G[1], u1G[2], u2Q[0], u2Q[1], u2Q[2], pp);
        if (P[2] == 0)
            return false;

        uint Px = EllipticCurve.invMod(P[2], p); // need Px/Pz^2
        Px = mulmod(P[0], mulmod(Px, Px, p), p);
        return Px % n == rs[0];
    }

    function pedersenCommitment(uint256 mask, uint256 val) internal pure returns(uint8 yBit, uint x) {
        (uint256 tempX, uint256 tempY) = EllipticCurve.ecMul(
            mask,
            Gx,
            Gy,
            AA,
            pp
        );
        (uint256 valx, uint256 valy) = EllipticCurve.ecMul(
            val,
            Hx,
            Hy,
            AA,
            pp
        );
        (uint256 qx, uint256 qy) = EllipticCurve.ecAdd(
            tempX, tempY,
            valx, valy,
            AA, pp
        );
        (yBit, x) = compressXY(qx, qy);
    }

    function mulWithH(uint256 privKey) internal pure returns(uint8 yBit, uint x) {
        (uint256 qx, uint256 qy) = EllipticCurve.ecMul(
            privKey,
            Hx,
            Hy,
            AA,
            pp
        );
        (yBit, x) = compressXY(qx, qy);
    }

    function mulWithHToPoint(uint256 privKey) internal pure returns(uint256 x, uint256 y) {
        (x, y) = EllipticCurve.ecMul(
            privKey,
            Hx,
            Hy,
            AA,
            pp
        );

    }

    /// @dev See Curve.compress
    function compress(uint[2] memory P) internal pure returns (uint8, uint) {
        assert(P.length == 2);
        return compressXY(P[0], P[1]);
    }

    function compressXY(uint _x, uint _y) internal pure returns (uint8 yBit, uint x) {
        x = _x;
        yBit = ((_y & 1)==1) ? 1 : 0;
    }

    /// @dev See Curve.decompress
    function decompress(uint8 yBit, uint x) internal pure returns (uint[2] memory P) {
        uint p = pp;
        uint y2 = addmod(mulmod(x, mulmod(x, x, p), p), 7, p);
        uint y_ = EllipticCurve.expMod(y2, (p + 1) / 4, p);
        uint cmp = yBit ^ y_ & 1;
        P[0] = x;
        P[1] = (cmp == 0) ? y_ : p - y_;
    }

    /// @dev See Curve.decompress
    function decompressXY(uint8 yBit, uint x) internal pure returns (uint X, uint Y) {
        uint p = pp;
        uint y2 = addmod(mulmod(x, mulmod(x, x, p), p), 7, p);
        uint y_ = EllipticCurve.expMod(y2, (p + 1) / 4, p);
        uint cmp = yBit ^ y_ & 1;
        X = x;
        Y = (cmp == 0) ? y_ : p - y_;
    }

    // Returns the inverse in the field of modulo n
    function inverse(uint256 num) internal pure
    returns(uint256 invNum)
    {
        uint256 t = 0;
        uint256 newT = 1;
        uint256 r = n;
        uint256 newR = num;
        uint256 q;
        while (newR != 0) {
            q = r / newR;

            (t, newT) = (newT, addmod(t, (n - mulmod(q, newT,n)), n));
            (r, newR) = (newR, r - q * newR );
        }

        invNum = t;
    }

    // Transform from projective to affine coordinates
    function toAffinePoint(uint256 x0, uint256 y0, uint256 z0) internal pure
    returns(uint256 x1, uint256 y1)
    {
        (x1, y1) = EllipticCurve.toAffine(x0, y0, z0, pp);
    }

    // Add two elliptic curve points (affine coordinates)
    function add(uint256 x0, uint256 y0,
        uint256 x1, uint256 y1) internal pure
    returns(uint256, uint256)
    {
        return EllipticCurve.ecAdd(x0, y0, x1, y1, AA, pp);
    }

    function sub(uint256 x0, uint256 y0,
        uint256 x1, uint256 y1) internal pure
    returns(uint256, uint256)
    {
        return EllipticCurve.ecSub(x0, y0, x1, y1, AA, pp);
    }

    // Multiplication dP. P affine, wNAF: w=5
    // Params: d, Px, Py
    // Output: Jacobian Q
    function _mul(uint d, uint[2] memory P) internal pure returns (uint[3] memory Q) {
        (Q[0], Q[1], Q[2]) = EllipticCurve.jacMul(
            d,
            P[0],
            P[1],
            1,
            AA,
            pp);
    }

}

library UnitUtils {
    using SafeMath for uint256;
    function Wei2Gwei(uint256 _amount) internal view returns (uint256) {
        return _amount.div(10**9);
    }

    function Gwei2Wei(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(10**9);
    }
}

library RingCTVerifier {
    address constant RINGCT_PRECOMPILED = 0x000000000000000000000000000000000000001e;
    address constant RINGCT_PRECOMPILED_MESSAGE = 0x000000000000000000000000000000000000001F;
    function VerifyRingCT(bytes memory data) internal returns (bool) {
        (bool success,) = RINGCT_PRECOMPILED.call(data);
        return success;
    }

    function VerifyRingCTWithMessage(bytes memory data) internal returns (bool) {
        (bool success,) = RINGCT_PRECOMPILED_MESSAGE.call(data);
        return success;
    }
    function ComputeSignatureSize(uint256 numRing, uint256 ringSize) internal pure returns (uint256) {
        return 8 + 8 + 32 + 32 + numRing*ringSize*32 + numRing*ringSize*33 + numRing*33;
    }
}

library BulletProofVerifier {
    address constant BP_PRECOMPILED = 0x0000000000000000000000000000000000000028;
    function VerifyRangeProof(bytes memory data) internal returns (bool) {
        (bool success,) = BP_PRECOMPILED.call(data);
        return success;
    }

    function CheckRangeProof(bytes memory data) internal returns (bool) {
        (bool success,) = BP_PRECOMPILED.call(data);
        require(success);
        return success;
    }
}

library CopyUtils {
    function Copy33Bytes(bytes memory data, uint256 _start) internal view returns (bool success, byte[33] memory ret) {
        if (data.length < _start + 33) {
            success = false;
        } else {
            for (uint256 i = _start; i < _start + 33; i++) {
                ret[i - _start] = data[i];
            }
            success = true;
        }
    }

    function Copy32Bytes(bytes memory data, uint256 _start) internal view returns (bool success, byte[32] memory ret) {
        if (data.length < _start + 32) {
            success = false;
        } else {
            for (uint256 i = _start; i < _start + 32; i++) {
                ret[i - _start] = data[i];
            }
            success = true;
        }
    }

    function Copy32Bytes2(bytes memory data, uint256 _start) internal view returns (bool success, byte[32] memory ret) {
        if (data.length < _start + 32) {
            success = false;
        } else {
            for (uint256 i = _start; i < _start + 32; i++) {
                ret[i - _start] = data[i];
            }
            success = true;
        }
    }

    function CompareBytes(bytes32 b1, bytes memory b2, uint256 _start) internal view returns (bool) {
        for (uint8 i = 0; i < 32; i++) {
            if (b1[i] != b2[_start + i]) return false;
        }
        return true;
    }

    function CopyBytes(bytes memory data, uint256 _start, uint256 _size) internal view returns (bool, byte[] memory) {
        byte[] memory ret;
        if (data.length < _start + _size) {
            return (false, ret);
        } else {
            ret = new byte[](_size);
            for (uint256 i = _start; i < _start + _size; i++) {
                ret[i - _start] = data[i];
            }
            return (true, ret);
        }
    }

    function BytesToUint(bytes32 b) internal view returns (uint256){
        uint256 number;
        for(uint256 j = 0;j < b.length; j++){
            number = number + (2**(8*(b.length-(j+1))))*uint256(uint8(b[j]));
        }
        return number;
    }

    function ConvertBytesToUint(bytes memory b, uint256 _start, uint256 _size) internal view returns (uint256){
        uint256 number;
        for(uint256 j = 0; j < _size; j++){
            number = number + (2**(8*(_size - (j+1))))*uint256(uint8(b[j + _start]));
        }
        return number;
    }

    function ConvertBytes33ToUint(byte[33] memory b, uint256 _start, uint256 _size) internal view returns (uint256){
        uint256 number;
        for(uint256 j = 0; j < _size; j++){
            number = number + (2**(8*(_size - (j+1))))*uint256(uint8(b[j + _start]));
        }
        return number;
    }
}

interface ITRC21 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function issuer() external view returns (address payable);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function estimateFee(uint256 value) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Fee(address indexed from, address indexed to, address indexed issuer, uint256 value);
}

contract TRC21 is ITRC21 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    uint256 private _minFee;
    address payable private _issuer;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev  The amount fee that will be lost when transferring.
     */
    function minFee() public view returns (uint256) {
        return _minFee;
    }

    /**
     * @dev token's foundation
     */
    function issuer() public view returns (address payable) {
        return _issuer;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Estimate transaction fee.
     * @param value amount tokens sent
     */
    function estimateFee(uint256 value) public view returns (uint256) {
        return value.mul(0).add(_minFee);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner,address spender) public	view returns (uint256){
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        uint256 total = value.add(_minFee);
        require(to != address(0));
        require(value <= total);
        _transfer(msg.sender, to, value);
        if (_minFee > 0) {
            _transfer(msg.sender, _issuer, _minFee);
            emit Fee(msg.sender, to, _issuer, _minFee);
        }
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        require(_balances[msg.sender] >= _minFee);
        _allowed[msg.sender][spender] = value;
        _transfer(msg.sender, _issuer, _minFee);
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from,	address to,	uint256 value)	public returns (bool) {
        uint256 total = value.add(_minFee);
        require(to != address(0));
        require(value <= total);
        require(total <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(total);
        _transfer(from, to, value);
        _transfer(from, _issuer, _minFee);
        emit Fee(msg.sender, to, _issuer, _minFee);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0x00));
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Transfers token's foundation to new issuer
     * @param newIssuer The address to transfer ownership to.
     */
    function _changeIssuer(address payable newIssuer) internal {
        require(newIssuer != address(0));
        _issuer = newIssuer;
    }

    /**
     * @dev Change minFee
     * @param value minFee
     */
    function _changeMinFee(uint256 value) internal {
        _minFee = value;
    }

}

contract MyTRC21 is TRC21 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals, uint256 cap, uint256 minFee) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _mint(msg.sender, cap);
        _changeIssuer(msg.sender);
        _changeMinFee(minFee);
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function setMinFee(uint256 value) public {
        require(msg.sender == issuer());
        _changeMinFee(value);
    }
}

contract PrivacyTRC21TOMO is MyTRC21 {
    constructor () MyTRC21("TomoP", "TPA", 18, 1000000000* (10**18), 0) public {}
}

library Memory {

    // Size of a word, in bytes.
    uint internal constant WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint internal constant BYTES_HEADER_SIZE = 32;
    // Address of the free memory pointer.
    uint internal constant FREE_MEM_PTR = 0x40;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint addr, uint addr2, uint len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'
    function equals(uint addr, uint len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        return equals(addr, addr2, len);
    }

    // Allocates 'numBytes' bytes in memory. This will prevent the Solidity compiler
    // from using this area of memory. It will also initialize the area by setting
    // each byte to '0'.
    function allocate(uint numBytes) internal pure returns (uint addr) {
        // Take the current value of the free memory pointer, and update.
        assembly {
            addr := mload(/*FREE_MEM_PTR*/0x40)
            mstore(/*FREE_MEM_PTR*/0x40, add(addr, numBytes))
        }
        uint words = (numBytes + WORD_SIZE - 1) / WORD_SIZE;
        for (uint i = 0; i < words; i++) {
            assembly {
                mstore(add(addr, mul(i, /*WORD_SIZE*/32)), 0)
            }
        }
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(uint src, uint dest, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Returns a memory pointer to the provided bytes array.
    function ptr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := bts
        }
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
        len = bts.length;
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        copy(addr, btsptr, len);
    }

    // Get the word stored at memory address 'addr' as a 'uint'.
    function toUint(uint addr) internal pure returns (uint n) {
        assembly {
            n := mload(addr)
        }
    }

    // Get the word stored at memory address 'addr' as a 'bytes32'.
    function toBytes32(uint addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }

    /*
    // Get the byte stored at memory address 'addr' as a 'byte'.
    function toByte(uint addr, uint8 index) internal pure returns (byte b) {
        require(index < WORD_SIZE);
        uint8 n;
        assembly {
            n := byte(index, mload(addr))
        }
        b = byte(n);
    }
    */
}

library Bytes {

    uint internal constant BYTES_HEADER_SIZE = 32;

    // Checks if two `bytes memory` variables are equal. This is done using hashing,
    // which is much more gas efficient then comparing each byte individually.
    // Equality means that:
    //  - 'self.length == other.length'
    //  - For 'n' in '[0, self.length)', 'self[n] == other[n]'
    function equals(bytes memory self, bytes memory other) internal pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint addr;
        uint addr2;
        assembly {
            addr := add(self, /*BYTES_HEADER_SIZE*/32)
            addr2 := add(other, /*BYTES_HEADER_SIZE*/32)
        }
        equal = Memory.equals(addr, addr2, self.length);
    }

    // Checks if two 'bytes memory' variables points to the same bytes array.
    // Technically this is done by de-referencing the two arrays in inline assembly,
    // and checking if the values are the same.
    function equalsRef(bytes memory self, bytes memory other) internal pure returns (bool equal) {
        assembly {
            equal := eq(self, other)
        }
    }

    // Copies a byte array.
    // Returns the copied bytes.
    // The function works by creating a new bytes array in memory, with the
    // same length as 'self', then copying all the bytes from 'self' into
    // the new array.
    function copy(bytes memory self) internal pure returns (bytes memory) {
        /*if (self.length == 0) {
            return bytes();
        }*/
        uint addr = Memory.dataPtr(self);
        return Memory.toBytes(addr, self.length);
    }

    // Copies a section of 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that 'startIndex <= self.length'
    // The length of the substring is: 'self.length - startIndex'
    function substr(bytes memory self, uint startIndex) internal pure returns (bytes memory) {
        require(startIndex <= self.length);
        uint len = self.length - startIndex;
        uint addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that:
    //  - 'startIndex + len <= self.length'
    // The length of the substring is: 'len'
    function substr(bytes memory self, uint startIndex, uint len) internal pure returns (bytes memory) {
        require(startIndex + len <= self.length);
        require(len > 0);
        uint addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    function copySubstr(bytes memory self, uint selfIndex, bytes memory from, uint fromIndex, uint len) internal pure {
        require(selfIndex + len <= self.length && fromIndex + len <= self.length);
        require(len > 0);
        uint addr = Memory.dataPtr(self);
        uint fromAddr = Memory.dataPtr(from);
        Memory.copy(fromAddr + fromIndex, addr + selfIndex, len);
    }

    // Combines 'self' and 'other' into a single array.
    // Returns the concatenated arrays:
    //  [self[0], self[1], ... , self[self.length - 1], other[0], other[1], ... , other[other.length - 1]]
    // The length of the new array is 'self.length + other.length'
    function concat(bytes memory self, bytes memory other) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        (uint src, uint srcLen) = Memory.fromBytes(self);
        (uint src2, uint src2Len) = Memory.fromBytes(other);
        (uint dest,) = Memory.fromBytes(ret);
        uint dest2 = dest + srcLen;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
        return ret;
    }

    // Combines 'self' and 'other1' and 'other2' into a single array.
    // Returns the concatenated arrays:
    //  [self[0], self[1], ... , self[self.length - 1], other[0], other[1], ... , other[other.length - 1]]
    // The length of the new array is 'self.length + other.length'
    function concat(bytes memory self, bytes memory other1, bytes memory other2) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other1.length + other2.length);
        uint[3] memory src;
        uint[3] memory srcLen;
        (src[0], srcLen[0]) = Memory.fromBytes(self);
        (src[1], srcLen[1]) = Memory.fromBytes(other1);
        (src[2], srcLen[2]) = Memory.fromBytes(other2);

        (uint dest,) = Memory.fromBytes(ret);
        Memory.copy(src[0], dest, srcLen[0]);
        Memory.copy(src[1], dest + srcLen[0], srcLen[1]);
        Memory.copy(src[2], dest + srcLen[0] + srcLen[1], srcLen[2]);
        return ret;
    }

    function copyTo(uint8 bit, uint256 x, bytes memory to, uint256 offset) internal pure {
        bytes memory bts = toBytesPubkey(x, bit);
        uint256 dest = Memory.dataPtr(to) + offset;
        Memory.copy(Memory.dataPtr(bts), dest, bts.length);
    }

    function copyTo(bytes memory self, bytes memory to, uint256 offset) internal pure {
        uint256 dest = Memory.dataPtr(to) + offset;
        Memory.copy(Memory.dataPtr(self), dest, self.length);
    }

    // Copies a section of a 'bytes32' starting at the provided 'startIndex'.
    // Returns the copied bytes (padded to the right) as a new 'bytes32'.
    // Requires that 'startIndex < 32'
    function substr(bytes32 self, uint8 startIndex) internal pure returns (bytes32) {
        require(startIndex < 32);
        return bytes32(uint(self) << startIndex*8);
    }

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the copied bytes (padded to the right) as a new 'bytes32'.
    // Requires that:
    //  - 'startIndex < 32'
    //  - 'startIndex + len <= 32'
    function substr(bytes32 self, uint8 startIndex, uint8 len) internal pure returns (bytes32) {
        require(startIndex < 32 && startIndex + len <= 32);
        return bytes32(uint(self) << startIndex*8 & ~uint(0) << (32 - len)*8);
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'
    // The returned bytes will be of length '32'.
    function toBytes(bytes32 self) internal pure returns (bytes memory bts) {
        bts = new bytes(32);
        assembly {
            mstore(add(bts, /*BYTES_HEADER_SIZE*/32), self)
        }
    }

    // Copies 'len' bytes from 'self' into a new 'bytes memory', starting at index '0'.
    // Returns the newly created 'bytes memory'
    // The returned bytes will be of length 'len'.
    function toBytes(bytes32 self, uint8 len) internal pure returns (bytes memory bts) {
        require(len <= 32);
        bts = new bytes(len);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint data = uint(self) & ~uint(0) << (32 - len)*8;
        assembly {
            mstore(add(bts, /*BYTES_HEADER_SIZE*/32), data)
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'
    // The returned bytes will be of length '20'.
    function toBytes(address self) internal pure returns (bytes memory bts) {
        bts = toBytes(bytes32(uint(self) << 96), 20);
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'
    // The returned bytes will be of length '32'.
    function toBytes(uint self) internal pure returns (bytes memory bts) {
        bts = toBytes(bytes32(self), 32);
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'
    // Requires that:
    //  - '8 <= bitsize <= 256'
    //  - 'bitsize % 8 == 0'
    // The returned bytes will be of length 'bitsize / 8'.
    function toBytes(uint self, uint16 bitsize) internal pure returns (bytes memory bts) {
        require(8 <= bitsize && bitsize <= 256 && bitsize % 8 == 0);
        self <<= 256 - bitsize;
        bts = toBytes(bytes32(self), uint8(bitsize / 8));
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'
    // The returned bytes will be of length '1', and:
    //  - 'bts[0] == 0 (if self == false)'
    //  - 'bts[0] == 1 (if self == true)'
    function toBytes(bool self) internal pure returns (bytes memory bts) {
        bts = new bytes(1);
        bts[0] = self ? bytes1(uint8(1)) : bytes1(0);
    }

    function toBytes(byte[] memory self) internal pure returns (bytes memory bts) {
        bts = new bytes(self.length);
        for (uint i = 0; i < self.length; i++) {
            bts[i] = self[i];
        }
    }

    function toBytesPubkey(uint256 self, uint8 bit) internal pure returns (bytes memory bts) {
        bts = new bytes(33);
        bytes32 temp = bytes32(self);
        bts[0] = byte(bit);
        for (uint i = 0; i < 32; i++) {
            bts[i + 1] = temp[i];
        }
    }

    // Computes the index of the highest byte set in 'self'.
    // Returns the index.
    // Requires that 'self != 0'
    // Uses big endian ordering (the most significant byte has index '0').
    function highestByteSet(bytes32 self) internal pure returns (uint8 highest) {
        highest = 31 - lowestByteSet(uint(self));
    }

    // Computes the index of the lowest byte set in 'self'.
    // Returns the index.
    // Requires that 'self != 0'
    // Uses big endian ordering (the most significant byte has index '0').
    function lowestByteSet(bytes32 self) internal pure returns (uint8 lowest) {
        lowest = 31 - highestByteSet(uint(self));
    }

    // Computes the index of the highest byte set in 'self'.
    // Returns the index.
    // Requires that 'self != 0'
    // Uses little endian ordering (the least significant byte has index '0').
    function highestByteSet(uint self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint ret;
        if (self & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 != 0) {
            ret += 16;
            self >>= 128;
        }
        if (self & 0xffffffffffffffff0000000000000000 != 0) {
            ret += 8;
            self >>= 64;
        }
        if (self & 0xffffffff00000000 != 0) {
            ret += 4;
            self >>= 32;
        }
        if (self & 0xffff0000 != 0) {
            ret += 2;
            self >>= 16;
        }
        if (self & 0xff00 != 0) {
            ret += 1;
        }
        highest = uint8(ret);
    }

    // Computes the index of the lowest byte set in 'self'.
    // Returns the index.
    // Requires that 'self != 0'
    // Uses little endian ordering (the least significant byte has index '0').
    function lowestByteSet(uint self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint ret;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self >>= 128;
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self >>= 64;
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self >>= 32;
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self >>= 16;
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        lowest = uint8(ret);
    }

}

contract pTRC21 is TRC21 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint8 constant PRIVACY_DECIMALS = 8;
    uint256 private _sendFee;
    uint256 private _depositFee;
    uint256 private _withdrawFee;
    address private _token;

    constructor (address token,
        string memory name,
        uint256 sendFee,
        uint256 depositFee,
        uint256 withdrawFee
    ) public {
        if (token != address(0)) {
            ITRC21 t = ITRC21(token);
            //require(t.issuer() == msg.sender);

            _token = token;
            _name =  string(abi.encodePacked("p", t.name()));

            _symbol = t.symbol();
            _decimals = t.decimals();
        } else {
            // Tomo token
            _token = address(0);
            _name = string(abi.encodePacked("p", name));
            _symbol = _name;
            _decimals = 18;
        }

        _sendFee = _toPrivacyValue(sendFee);
        _depositFee = _toPrivacyValue(depositFee);
        _withdrawFee = _toPrivacyValue(withdrawFee);

        _changeIssuer(msg.sender);
    }


    // convert external value to privacy's
    function _toPrivacyValue(uint256 value) internal view returns (uint256) {
        if (_decimals >= PRIVACY_DECIMALS) {
            uint256 expDiff = 10**uint256(_decimals - PRIVACY_DECIMALS);
            return value.div(expDiff);
        } else {
            uint256 expDiff = 10**uint256(PRIVACY_DECIMALS - _decimals);
            return value.mul(expDiff);
        }
    }

    // convert external value to privacy's
    function _toExternalValue(uint256 value) internal view returns (uint256) {
        if (_decimals >= PRIVACY_DECIMALS) {
            uint256 expDiff = 10**uint256(_decimals - PRIVACY_DECIMALS);
            return value.mul(expDiff);
        } else {
            uint256 expDiff = 10**uint256(PRIVACY_DECIMALS - _decimals);
            return value.div(expDiff);
        }
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return the number of decimals of the token.
     */
    function token() public view returns (address) {
        return _token;
    }

    /**
     * @return the number of decimals of the token.
     */
    function privacyDecimals() public pure returns (uint8) {
        return PRIVACY_DECIMALS;
    }

    function setSendingFee(uint256 value) public {
        require(msg.sender == issuer());
        _sendFee = _toPrivacyValue(value);
    }

    function setDepositFee(uint256 value) public {
        require(msg.sender == issuer());
        _depositFee = _toPrivacyValue(value);
    }

    function setWithdrawFee(uint256 value) public {
        require(msg.sender == issuer());
        _withdrawFee = _toPrivacyValue(value);
    }

    function getSendFee() public view returns (uint256) {
        return _sendFee;
    }

    function getDepositFee() public view returns (uint256) {
        return _depositFee;
    }

    function getWithdrawFee() public view returns (uint256) {
        return _withdrawFee;
    }
}

contract Privacy is pTRC21{
    using SafeMath for uint256;
    using UnitUtils for uint256;

    struct CompressPubKey {
        uint8 yBit;
        uint256 x;
    }

    struct RawUTXO {
        uint256[3] XBits;
        uint8[3] YBits;
        uint256[2] encodeds;
        uint256 index;
        uint256 txID;
    }

    struct NewUTXOEventStruct {
        uint256[3] Xs;   //commitmentX, pubkeyX, txPubX
        uint8[3] YBits;        //commitmentYBit, pubkeyYBit, _txPubYBit
        uint256[2] amount;
        uint256 index;
        uint256 txIndex;
    }

    struct UTXO {
        CompressPubKey[3] keys; //commitmentX, pubkeyX, txPubX
        uint256 amount; //encoded amount
        uint256 mask;   //encoded mask
        uint256 txID;
    }

    struct Transaction {
        uint[] utxoIndexes;   //indexes of utxos created by the transaction
        byte[137] data;
    }

    UTXO[] public utxos;
    Transaction[] txs;

    mapping(uint256 => bool) keyImagesMapping;

    //--------------------------EVENTS---------------------------------
    event NewUTXO(uint256[3] _Xs,   //commitmentX, pubkeyX, txPubX
        uint8[3] _YBits,        //commitmentYBit, pubkeyYBit, _txPubYBit
        uint256[2] _amount,
        uint256 _index,
        uint256 _txIndex);
    event TransactionFee(address _issuer, uint256 _amount);
    event NewTransaction(uint256 _txIndex, NewUTXOEventStruct[] _utxos, byte[137] _data);

    /**the first step for every one to use private transactions is deposit to the contract
    *@param {_pubkeyX} One time generated public key of the recipient for the deposit
    *@param {_pubkeyY} One time generated public key of the recipient for the deposit
    *@param {_txPubKeyX} One time generated transaction public key of the recipient for the deposit
    *@param {_txPubKeyY} One time generated transaction public key of the recipient for the deposit
    *@param {_mask} One time generated transaction public key of the recipient for the deposit
    *@param {_amount} One time generated transaction public key of the recipient for the deposit
    *@param {_encodedMask} One time generated transaction public key of the recipient for the deposit
    */
    function _deposit(
        uint256 value, // to new decimal already
        uint _pubkeyX,
        uint _pubkeyY,
        uint _txPubKeyX,
        uint _txPubKeyY,
        uint256 _mask,
        uint256 _amount,
        uint256 _encodedMask,
        byte[137] memory _data) internal {
        require(Secp256k1.onCurveXY(_pubkeyX, _pubkeyY));
        require(Secp256k1.onCurveXY(_txPubKeyX, _txPubKeyY));

        (uint8 _ybitComitment, uint xCommitment) = Secp256k1.pedersenCommitment(_mask, value.sub(getDepositFee()));
        (uint8 pybit, uint px) = Secp256k1.compressXY(_pubkeyX, _pubkeyY);
        (uint8 txybit, uint txx) = Secp256k1.compressXY(_txPubKeyX, _txPubKeyY);

        utxos.length = utxos.length + 1;
        utxos[utxos.length - 1].keys[0] = CompressPubKey(_ybitComitment + 2, xCommitment);
        utxos[utxos.length - 1].keys[1] = CompressPubKey(pybit + 2, px);
        utxos[utxos.length - 1].keys[2] = CompressPubKey(txybit + 2, txx);
        utxos[utxos.length - 1].amount = _amount;
        utxos[utxos.length - 1].mask = _encodedMask;
        utxos[utxos.length - 1].txID = txs.length;

        UTXO storage lastUTXO = utxos[utxos.length.sub(1)];
        emit NewUTXO([lastUTXO.keys[0].x, lastUTXO.keys[1].x, lastUTXO.keys[2].x],
            [lastUTXO.keys[0].yBit, lastUTXO.keys[1].yBit, lastUTXO.keys[2].yBit],
            [lastUTXO.amount, lastUTXO.mask],
            utxos.length.sub(1),
            txs.length);

        addNewTransaction(_data, 1);
        transferFee(getDepositFee());
    }

    /**Send TOMO/Token privately
    *@param {_inputIDs} The index IDs of all decoys in all input rings, data is structured as [ring00,ring01,ring02,ring11...]
    *@param {_outputs} commitments, stealth addresses and transaction pubkeys of outputs produced by this private send
    *@param {_amounts} enrypted/encoded format of transaction outputs amounts and masks/blinding factors
    *@param {_ringSignature} ring signature that will be verified by precompiled contract
    */
    function privateSend(uint256[] memory _inputIDs,
        uint256[] memory _outputs, //1/3 for commitments, 1/3 for stealths,, 1/3 for txpubs
        uint256[] memory _amounts, //1/2 for encryptd amounts, 1/2 for masks
        bytes memory _ringSignature,
        bytes memory _bp,
        byte[137] memory _data) public {

        require(_inputIDs.length < 100, "too many inputs");
        require(_inputIDs.length > 0, "no inputs");
        require(_outputs.length % 6 == 0 && _outputs.length <= 2*6);
        require(_amounts.length.div(2) == _outputs.length.div(6));

        //verify signature size
        require(_ringSignature.length > 16);
        //[0]: numRing
        //[1]: ringSize
        //[2]: key images offset
        //[3]: key images offset
        uint256[4] memory ringParams;
        ringParams[0] = CopyUtils.ConvertBytesToUint(_ringSignature, 0, 8);    //numRing
        ringParams[1] = CopyUtils.ConvertBytesToUint(_ringSignature, 8, 8);    //ringSize
        require(_inputIDs.length % (ringParams[1]) == 0);
        require(RingCTVerifier.ComputeSignatureSize(ringParams[0], ringParams[1]) == _ringSignature.length + ringParams[0]*ringParams[1]*33);

        ringParams[2] = 80 + ringParams[0] * ringParams[1] *32;
        ringParams[3] = ringParams[2];//ringParams[2] + ringParams[0] * ringParams[1] * 33;

        bytes memory fullRingCT = new bytes(RingCTVerifier.ComputeSignatureSize(ringParams[0], ringParams[1]));
        uint256 fullRingCTOffSet = 0;
        //testing: copy entire _ring to fullRingCT
        Bytes.copySubstr(fullRingCT, 0, _ringSignature, 0, ringParams[2]);

        fullRingCTOffSet += ringParams[2];

        //verify public keys is correct, the number of pubkey inputs = ringParams[0] * ringParams[1]
        //pubkeys start from offset: 80 + ringParams[0] * ringParams[1] *32
        //this does not verify additional ring (the last ring)
        fullRingCTOffSet = copyRingKeys(fullRingCT, fullRingCTOffSet, _inputIDs, ringParams[0], ringParams[1]);

        //verify additional ring
        //compute sum of outputs
        uint256[2] memory outSum;
        //adding fee to sum of output commitments
        (outSum[0], outSum[1]) = Secp256k1.mulWithHToPoint(getSendFee());
        for (uint256 i = 0; i < _outputs.length.div(6); i++) {
            (outSum[0], outSum[1]) = Secp256k1.add(outSum[0], outSum[1], _outputs[i*2], _outputs[i*2+1]);
        }

        fullRingCTOffSet = computeAdditionalRingKeys(_inputIDs, fullRingCT, ringParams, fullRingCTOffSet, outSum);

        Bytes.copySubstr(fullRingCT, fullRingCTOffSet, _ringSignature, ringParams[3], ringParams[0]*33);

        //verify key image spend
        verifyKeyImageSpent(ringParams[0], _ringSignature, ringParams[3]);

        //verify ringSignature
        require(RingCTVerifier.VerifyRingCT(fullRingCT), "signature failed");
        transferFee(getSendFee());

        //create output UTXOs
        uint256 outputLength = _outputs.length.div(6);
        for (uint256 i = 0; i < outputLength; i++) {
            uint256[3] memory X;
            uint8[3] memory yBit;
            (yBit[0], X[0]) = Secp256k1.compressXY(_outputs[i*2], _outputs[i*2 + 1]);
            //overwrite commitment in range proof
            Bytes.copyTo(yBit[0] + 2, X[0], _bp, 4 + i*33);

            (yBit[1], X[1]) = Secp256k1.compressXY(_outputs[outputLength*2 + i*2], _outputs[outputLength*2 + i*2 + 1]);

            (yBit[2], X[2]) = Secp256k1.compressXY(_outputs[outputLength*4 + i*2], _outputs[outputLength*4 + i*2 + 1]);

            utxos.length = utxos.length + 1;
            utxos[utxos.length - 1].keys[0] = CompressPubKey(yBit[0] + 2, X[0]);
            utxos[utxos.length - 1].keys[1] = CompressPubKey(yBit[1] + 2, X[1]);
            utxos[utxos.length - 1].keys[2] = CompressPubKey(yBit[2] + 2, X[2]);
            utxos[utxos.length - 1].amount = _amounts[i];
            utxos[utxos.length - 1].mask = _amounts[outputLength + i];
            utxos[utxos.length - 1].txID = txs.length;

            emit NewUTXO([utxos[utxos.length - 1].keys[0].x, utxos[utxos.length - 1].keys[1].x, utxos[utxos.length - 1].keys[2].x],
                [utxos[utxos.length - 1].keys[0].yBit, utxos[utxos.length - 1].keys[1].yBit, utxos[utxos.length - 1].keys[2].yBit],
                [utxos[utxos.length - 1].amount, utxos[utxos.length - 1].mask],
                utxos.length - 1,
                txs.length);
        }
        //verify bulletproof
        require(BulletProofVerifier.VerifyRangeProof(_bp), "bulletproof verification failed");

        addNewTransaction(_data, outputLength);
    }

    function copyRingKeys(bytes memory _dest, uint256 _inOffset, uint256[] memory _inputIDs, uint256 _numRing, uint256 _ringSize) internal view returns (uint256) {
        uint256 offset = _inOffset;
        for(uint256 loopVars0 = 0; loopVars0 < _numRing - 1; loopVars0++) {
            for(uint256 loopVars1 = 0; loopVars1 < _ringSize; loopVars1++) {
                //copy x and ybit serialized to fullRingCT
                Bytes.copyTo(
                    utxos[_inputIDs[loopVars0*(_ringSize) + loopVars1]].keys[1].yBit,
                    utxos[_inputIDs[loopVars0*(_ringSize) + loopVars1]].keys[1].x,
                    _dest, offset
                );
                offset += 33;
            }
        }
        return offset;
    }
    function verifyKeyImageSpent(uint256 _numRing, bytes memory _ringSignature, uint256 _from) internal {
        for(uint256 loopVars = 0; loopVars < _numRing; loopVars++) {
            (bool success, byte[33] memory ki) = CopyUtils.Copy33Bytes(_ringSignature, _from + loopVars*33);
            require(success);
            uint256 kiHash = CopyUtils.BytesToUint(keccak256(abi.encodePacked(ki)));
            require(!keyImagesMapping[kiHash], "key image is spent!");
            keyImagesMapping[kiHash] = true;
        }
    }

    function computeAdditionalRingKeys(uint256[] memory _inputIDs, bytes memory fullRingCT, uint256[4] memory ringParams, uint256 _inOffset, uint256[2] memory outSum) internal view returns (uint256){
        uint256 fullRingCTOffSet = _inOffset;
        uint256[2] memory loopVars;
        for(loopVars[1] = 0; loopVars[1] < ringParams[1]; loopVars[1]++) {
            uint256[8] memory point = [uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0)];
            //compute sum of: all input pubkeys + all input commitments
            for(loopVars[0] = 0; loopVars[0] < ringParams[0] - 1; loopVars[0]++) {
                if (point[0] == uint256(0)) {
                    (point[0], point[1]) = Secp256k1.decompressXY(utxos[_inputIDs[loopVars[0]*ringParams[1] + loopVars[1]]].keys[1].yBit%2,
                        utxos[_inputIDs[loopVars[0]*ringParams[1] + loopVars[1]]].keys[1].x);

                    uint256[2] memory commitment = Secp256k1.decompress(utxos[_inputIDs[loopVars[0]*ringParams[1] + loopVars[1]]].keys[0].yBit%2,
                        utxos[_inputIDs[loopVars[0]*ringParams[1] + loopVars[1]]].keys[0].x);

                    (point[0], point[1]) = Secp256k1.add(point[0], point[1], commitment[0], commitment[1]);
                } else {
                    uint256[2] memory temp = Secp256k1.decompress(utxos[_inputIDs[loopVars[0]*ringParams[1] + loopVars[1]]].keys[1].yBit%2,
                        utxos[_inputIDs[loopVars[0]*ringParams[1] + loopVars[1]]].keys[1].x);
                    (point[0], point[1]) = Secp256k1.add(point[0], point[1], temp[0], temp[1]);
                    temp = Secp256k1.decompress(utxos[_inputIDs[loopVars[0]*ringParams[1] + loopVars[1]]].keys[0].yBit%2,
                        utxos[_inputIDs[loopVars[0]*ringParams[1] + loopVars[1]]].keys[0].x);
                    (point[0], point[1]) = Secp256k1.add(point[0], point[1], temp[0], temp[1]);
                }
            }

            (point[2], point[3]) = Secp256k1.sub(point[0], point[1], outSum[0], outSum[1]);
            (uint8 yBit, uint256 compressX) = Secp256k1.compressXY(point[2], point[3]);
            Bytes.copyTo(yBit + 2, compressX, fullRingCT, fullRingCTOffSet);
            fullRingCTOffSet += 33;
        }
        return fullRingCTOffSet;
    }


    /**Withdraw TOMO/Token privately without revealing which output is being spent
    *@param {_inputIDs} The index IDs of all decoys in all input rings, data is structured as [ring00,ring01,ring02,ring11...]
    *@param {_outputs} commitments, stealth addresses and transaction pubkeys of outputs produced by this private send
    *@param {_withdrawalAmount} the amount to be withdrawn
    *@param {_amounts} enrypted/encoded format of transaction outputs amounts and masks/blinding factors
    *@param {_recipient} the recipient of the withdrawing transaction
    *@param {_ringSignature} ring signature that will be verified by precompiled contract
    */
    function withdrawFunds(uint[] memory _inputIDs, //multiple rings
        uint256[] memory _outputs, //1/3 for commitments, 1/3 for stealths,, 1/3 for txpubs : only contain 1 output
        uint256 _withdrawalAmount,
        uint256[2] memory _amounts, // _amounts[0]: encrypted amount, _amounts[1]: encrypted mask
        address payable _recipient,
        bytes memory _ringSignature,
        bytes memory _bp,
        byte[137] memory _data) public {

        require(_recipient != address(0x0), "recipient address invalid");
        require(_inputIDs.length < 100, "too many inputs");
        require(_inputIDs.length > 0, "no inputs");
        require(_outputs.length % 6 == 0 && _outputs.length <= 2*6);
        require(1 == _outputs.length.div(6));

        //verify signature size
        require(_ringSignature.length > 16);
        //[0]: numRing
        //[1]: ringSize
        //[2]: public offset
        //[3]: key images offset
        uint256[4] memory ringParams;

        ringParams[0] = CopyUtils.ConvertBytesToUint(_ringSignature, 0, 8);    //numRing
        ringParams[1] = CopyUtils.ConvertBytesToUint(_ringSignature, 8, 8);    //ringSize

        require(_inputIDs.length % (ringParams[1]) == 0);

        require(RingCTVerifier.ComputeSignatureSize(ringParams[0], ringParams[1]) == _ringSignature.length + ringParams[0]*ringParams[1]*33);

        ringParams[2] = 80 + ringParams[0] * ringParams[1] *32;
        ringParams[3] = ringParams[2];

        //verify key image spend
        verifyKeyImageSpent(ringParams[0], _ringSignature, ringParams[3]);

        bytes memory fullRingCT = new bytes(RingCTVerifier.ComputeSignatureSize(ringParams[0], ringParams[1]));
        uint256 fullRingCTOffSet = 0;
        //testing: copy entire _ring to fullRingCT
        Bytes.copySubstr(fullRingCT, 0, _ringSignature, 0, ringParams[2]);

        fullRingCTOffSet += ringParams[2];

        //verify public keys is correct, the number of pubkey inputs = ringParams[0] * ringParams[1]
        //pubkeys start from offset: 80 + ringParams[0] * ringParams[1] *32
        //this does not verify additional ring (the last ring)
        fullRingCTOffSet = copyRingKeys(fullRingCT, fullRingCTOffSet, _inputIDs, ringParams[0], ringParams[1]);

        //verify additional ring
        //compute sum of outputs
        uint256[2] memory outSum;
        //withdrawal amount + fee to commitment
        (outSum[0], outSum[1]) = Secp256k1.mulWithHToPoint(_toPrivacyValue(_withdrawalAmount).add(getWithdrawFee()));

        (outSum[0], outSum[1]) = Secp256k1.add(outSum[0], outSum[1], _outputs[0], _outputs[1]);

        //compute additional ring
        fullRingCTOffSet = computeAdditionalRingKeys(_inputIDs, fullRingCT, ringParams, fullRingCTOffSet, outSum);

        //copy key images
        Bytes.copySubstr(fullRingCT, fullRingCTOffSet, _ringSignature, ringParams[3], ringParams[0]*33);

        //verify ringSignature
        require(RingCTVerifier.VerifyRingCT(fullRingCT), "signature failed");

        //transfer
        // _recipient.transfer(_withdrawalAmount);
        doTransferOut(_recipient, _withdrawalAmount);

        //transfer fee
        transferFee(getWithdrawFee());

        uint256[3] memory X;
        uint8[3] memory yBit;
        (yBit[0], X[0]) = Secp256k1.compressXY(_outputs[0], _outputs[1]);
        //overwrite bulletproof range proof with commitment
        Bytes.copyTo(yBit[0] + 2, X[0], _bp, 4);
        //verify bulletproof
        require(BulletProofVerifier.VerifyRangeProof(_bp), "bulletproof verification failed");

        (yBit[1], X[1]) = Secp256k1.compressXY(_outputs[2], _outputs[3]);

        (yBit[2], X[2]) = Secp256k1.compressXY(_outputs[4], _outputs[5]);

        utxos.length = utxos.length + 1;
        utxos[utxos.length - 1].keys[0] = CompressPubKey(yBit[0] + 2, X[0]);
        utxos[utxos.length - 1].keys[1] = CompressPubKey(yBit[1] + 2, X[1]);
        utxos[utxos.length - 1].keys[2] = CompressPubKey(yBit[2] + 2, X[2]);
        utxos[utxos.length - 1].amount = _amounts[0];
        utxos[utxos.length - 1].mask = _amounts[1];
        utxos[utxos.length - 1].txID = txs.length;

        emit NewUTXO([utxos[utxos.length - 1].keys[0].x, utxos[utxos.length - 1].keys[1].x, utxos[utxos.length - 1].keys[2].x],
            [utxos[utxos.length - 1].keys[0].yBit, utxos[utxos.length - 1].keys[1].yBit, utxos[utxos.length - 1].keys[2].yBit],
            [utxos[utxos.length - 1].amount, utxos[utxos.length - 1].mask],
            utxos.length - 1,
            txs.length);
        addNewTransaction(_data, 1);
    }

    function transferFee(uint256 fee) internal;
    function doTransferOut(address payable to, uint256 amount) internal;

    function addNewTransaction(byte[137] memory _data, uint256 _numUTXO) internal {
        //emit new transaction
        txs.length = txs.length + 1;
        NewUTXOEventStruct[] memory newUTXOs = new NewUTXOEventStruct[](_numUTXO);
        for(uint i = utxos.length - _numUTXO; i < utxos.length; i++) {
            txs[txs.length - 1].utxoIndexes.push(i);
            txs[txs.length - 1].data = _data;

            newUTXOs[i + _numUTXO - utxos.length].Xs = [utxos[i].keys[0].x, utxos[i].keys[1].x, utxos[i].keys[2].x];
            newUTXOs[i + _numUTXO - utxos.length].YBits = [utxos[i].keys[0].yBit, utxos[i].keys[1].yBit, utxos[i].keys[2].yBit];
            newUTXOs[i + _numUTXO - utxos.length].amount = [utxos[i].amount, utxos[i].mask];
            newUTXOs[i + _numUTXO - utxos.length].index = i;
            newUTXOs[i + _numUTXO - utxos.length].txIndex = txs.length - 1;
        }

        emit NewTransaction(
            txs.length - 1, newUTXOs, _data
        );
    }

    function getTransactions(uint256[] memory _indexes) public view returns (uint256[] memory, NewUTXOEventStruct[] memory, byte[] memory) {
        uint256 numUTXO = 0;
        uint256 numValidTx = 0;
        uint256 utxoIterator = 0;
        for(uint i = 0; i < _indexes.length; i++) {
            if (_indexes[i] >= txs.length) break;
            numUTXO += txs[_indexes[i]].utxoIndexes.length;
            numValidTx++;
        }
        NewUTXOEventStruct[] memory retUTXOs = new NewUTXOEventStruct[](numUTXO);
        byte[] memory data = new byte[](numValidTx*137);
        for(uint i = 0; i < _indexes.length; i++) {
            if (_indexes[i] >= txs.length) break;
            uint256 txNumUTXO = txs[i].utxoIndexes.length;
            uint256[] storage utxoIndexes = txs[i].utxoIndexes;
            for(uint j = 0; j < txNumUTXO; j++) {
                UTXO storage utxo = utxos[utxoIndexes[j]];
                retUTXOs[utxoIterator].Xs = [utxo.keys[0].x, utxo.keys[1].x, utxo.keys[2].x];
                retUTXOs[utxoIterator].YBits = [utxo.keys[0].yBit, utxo.keys[1].yBit, utxo.keys[2].yBit];
                retUTXOs[utxoIterator].amount = [utxo.amount, utxo.mask];
                retUTXOs[utxoIterator].index = utxoIndexes[j];
                retUTXOs[utxoIterator].txIndex = utxo.txID;
                utxoIterator++;
            }

            for(uint k = 0; k < 137; k++) {
                data[i*137 + k] = txs[i].data[k];
            }
        }

        return (_indexes, retUTXOs, data);
    }

    function getUTXO(uint256 index) public view returns (uint256[3] memory,
        uint8[3] memory,
        uint256[2] memory, //0. encrypted amount, 1. encrypted mask
        uint256,
        uint256
    ) {
        return (
        [utxos[index].keys[0].x, utxos[index].keys[1].x, utxos[index].keys[2].x],
        [utxos[index].keys[0].yBit, utxos[index].keys[1].yBit, utxos[index].keys[2].yBit],
        [utxos[index].amount,utxos[index].mask],
        index,
        utxos[index].txID
        );
    }

    function getUTXOs(uint256[] memory indexs) public view returns (RawUTXO[] memory) {
        RawUTXO[] memory utxs = new RawUTXO[](indexs.length);
        // just a limit each request
        require(indexs.length < 200);

        for(uint8 i = 0; i < indexs.length; i++) {
            uint256 index = indexs[i];
            // utxs.length += 1;
            RawUTXO memory utxo = utxs[i];
            if (utxos.length <= index) {
                return utxs;
            }
            utxo.XBits = [utxos[index].keys[0].x, utxos[index].keys[1].x, utxos[index].keys[2].x];
            utxo.YBits = [utxos[index].keys[0].yBit, utxos[index].keys[1].yBit, utxos[index].keys[2].yBit];
            utxo.encodeds = [utxos[index].amount, utxos[index].mask];
            utxo.index = index;
            utxo.txID = utxos[index].txID;
        }

        return utxs;
    }

    function totalUTXO() public view returns (uint256) {
        return utxos.length;
    }

    function getTxs(uint256[] memory indexs) public view returns (Transaction[] memory) {
        Transaction[] memory result_txs = new Transaction[](indexs.length);
        // just a limit each request
        require(indexs.length < 200);

        for(uint8 i = 0; i < indexs.length; i++) {
            uint256 index = indexs[i];

            Transaction memory ptx = result_txs[i];
            if (txs.length <= index) {
                return result_txs;
            }
            ptx.utxoIndexes = txs[index].utxoIndexes;
            ptx.data = txs[index].data;
        }

        return result_txs;
    }

    function getLatestTx() public view returns (uint) {
        return txs.length;
    }

    function isSpent(byte[] memory keyImage) public view returns (bool) {
        uint256 kiHash = CopyUtils.BytesToUint(keccak256(abi.encodePacked(keyImage)));
        return keyImagesMapping[kiHash];
    }

    function areSpent(bytes memory keyImages) public view returns (bool[] memory) {
        require(keyImages.length < 200 * 33);

        uint256 numberKeyImage = keyImages.length / 33;
        bool[] memory result = new bool[](numberKeyImage);

        for(uint256 i = 0; i < numberKeyImage; i++) {
            (bool success, byte[33] memory ki) = CopyUtils.Copy33Bytes(keyImages, i*33);
            require(success);
            uint256 kiHash = CopyUtils.BytesToUint(keccak256(abi.encodePacked(ki)));
            result[i] = keyImagesMapping[kiHash];
        }

        return result;
    }

    //dont receive any money via default callback
    function () external payable {
        revert();
    }
}

contract pTomo is Privacy {
    bool public isActivated = false;
    address[] public earlyDepositers;
    uint public MIN_EARLY_DEPOSIT;
    uint public MAX_EARLY_DEPOSITER;
    uint public START_DEPOSITING_BLOCK;
    event Activated();
    event NewDeposit(address depositer, uint256 amount);

    modifier onlyActivated() {
        require(isActivated == true);
        _;
    }

    constructor (address token,
        string memory name,
        uint256 sendingFee,
        uint256 depositFee,
        uint256 withdrawFee,
        uint256 minEarlyDeposit,
        uint256 maxEarlyDepositer,
        uint256 startBlock
    )  pTRC21(token, name, sendingFee, depositFee, withdrawFee) public {
        MIN_EARLY_DEPOSIT = minEarlyDeposit;
        MAX_EARLY_DEPOSITER = maxEarlyDepositer;
        START_DEPOSITING_BLOCK = startBlock;
    }

    function deposit(
        uint256 value, // uniform interface with deposit token
        uint _pubkeyX,
        uint _pubkeyY,
        uint _txPubKeyX,
        uint _txPubKeyY,
        uint256 _mask,
        uint256 _amount,
        uint256 _encodedMask,
        byte[137] memory _data) public payable {
        require(block.number >= START_DEPOSITING_BLOCK);

        // convert deposit value to right decimals
        uint256 _value = _toPrivacyValue(msg.value);
        require(_value > getDepositFee(), "deposit amount must be greater than deposit fee");

        _deposit(
            _value,
            _pubkeyX,
            _pubkeyY,
            _txPubKeyX,
            _txPubKeyY,
            _mask,
            _amount,
            _encodedMask,
            _data);

        if (isActivated == false && msg.value >= MIN_EARLY_DEPOSIT) {
            _addDepositer(msg.sender, msg.value);
        }
    }

    function _addDepositer(address depositer, uint256 value) internal {
        // check duplicated address
        bool isMarked = false;
        for(uint i = 0; i < earlyDepositers.length; i++) {
            if (earlyDepositers[i] == depositer) {
                isMarked = true;
                break;
            }
        }

        if (isMarked) {
            return;
        }

        earlyDepositers.length = earlyDepositers.length + 1;
        earlyDepositers[earlyDepositers.length - 1] = depositer;
        emit NewDeposit(depositer, value);

        if (earlyDepositers.length == MAX_EARLY_DEPOSITER) {
            isActivated = true;
            emit Activated();
        }
    }

    function privateSend(uint256[] memory _inputIDs,
        uint256[] memory _outputs, //1/3 for commitments, 1/3 for stealths,, 1/3 for txpubs
        uint256[] memory _amounts, //1/2 for encryptd amounts, 1/2 for masks
        bytes memory _ringSignature,
        bytes memory _bp,
        byte[137] memory _data) public onlyActivated {
        super.privateSend(_inputIDs, _outputs, _amounts, _ringSignature, _bp, _data);
    }

    function withdrawFunds(uint[] memory _inputIDs, //multiple rings
        uint256[] memory _outputs, //1/3 for commitments, 1/3 for stealths,, 1/3 for txpubs : only contain 1 output
        uint256 _withdrawalAmount,
        uint256[2] memory _amounts, // _amounts[0]: encrypted amount, _amounts[1]: encrypted mask
        address payable _recipient,
        bytes memory _ringSignature,
        bytes memory _bp,
        byte[137] memory _data) public onlyActivated {
        super.withdrawFunds(_inputIDs, _outputs, _withdrawalAmount, _amounts, _recipient, _ringSignature, _bp, _data);
    }

    function transferFee(uint256 fee) internal {
        uint256 _externalValue = _toExternalValue(fee);
        issuer().transfer(
            _externalValue
        );
        emit TransactionFee(issuer(), _externalValue);
    }

    function doTransferOut(address payable to, uint256 amount) internal {
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
    }
}

