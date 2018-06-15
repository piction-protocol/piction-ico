pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "contracts/utils/ExtendsOwnable.sol";

/**
 * @title Product
 * @dev Simpler version of Product interface
 */
contract Product is ExtendsOwnable {
    using SafeMath for uint256;

    string public name;
    uint256 public maxcap;
    uint256 public weiRaised;
    uint256 public exceed;
    uint256 public minimum;
    uint256 public rate;
    uint256 public lockup;

    constructor (
        string _name,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        uint256 _lockup
    ) public {
        require(_maxcap > _minimum);

        name = _name;
        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;
        lockup = _lockup;
    }

    function addWeiRaised(uint256 _weiRaised) public onlyOwner {
        require(weiRaised <= _weiRaised);

        weiRaised = _weiRaised;
    }

    function subWeiRaised(uint256 _weiRaised) public onlyOwner {
        require(weiRaised >= _weiRaised);

        weiRaised = weiRaised.sub(_weiRaised);
    }
}
