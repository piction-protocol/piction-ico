pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../utils/Ownable.sol";

contract TokenDistributor is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        uint256 amount;
        uint256 criterionTime;
        bool release;
    }

    ERC20 token;
    mapping (address => mapping (address => Purchased)) purchasedList;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    constructor(address _token) {
        token = ERC20(_token);
    }

    function addPrucahsed(address _buyer, address _product, uint256 _amount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        //TODO require
        purchasedList[_buyer][_product] = Purchased(_amount, 0, false);
    }

    function getAmount(address _buyer, address _product)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
        returns(uint256)
    {
        //TODO require
        return purchasedList[_buyer][_product].amount
    }

    function setCriterionTime(address _buyer, address _product, uint256 _criterionTime)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        //TODO require
        purchasedList[_buyer][_product].criterionTime = _criterionTime;
    }

    function release(address _buyer, address _product)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        //TODO require
        //release check
        //blockTime check

        //TODO purchasedList[_buyer][_product].release = true
        //TODO token safeTransfer
    }
}
