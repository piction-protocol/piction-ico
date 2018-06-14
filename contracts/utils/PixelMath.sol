pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract PixelMath {
    using SafeMath for uint256;

    function min(uint256 val1, uint256 val2) public pure returns (uint256){
        return (val1 > val2) ? val2 : val1;
    }

    function max(uint256 val1, uint256 val2) public pure returns (uint256){
        return (val1 > val2) ? a : b;
    }
}
