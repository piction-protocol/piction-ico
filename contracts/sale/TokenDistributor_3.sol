pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../utils/Ownable.sol";

contract TokenDistributor_3 is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        address buyer;
        address product;
        uint256 amount;
        uint256 criterionTime;
        bool release;
        bool refund;
    }

    ERC20 token;
    Purchased[] purchasedList;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    constructor(address _token) {
        token = ERC20(_token);
    }

    function addPurchased(address _buyer, address _product, uint256 _amount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        //TODO require
        purchasedList.push(Purchased(_buyer, _product, _amount, 0, false, false));
    }

    function getAmount(address _buyer, address _product)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
        returns(uint256)
    {
        //TODO require

        for(uint index=0; index < purchasedList.length; index++) {
            if (purchasedList[index].buyer == _buyer
                && purchasedList[index].product == _product) {
                return purchasedList[index].amount;
            }
        }
        return 0;
    }

    function setCriterionTime(address _product, uint256 _criterionTime)
        external
        onlyOwner
        validAddress(_product)
    {
        //TODO require

        for(uint index=0; index < purchasedList.length; index++) {
            if (purchasedList[index].product == _product) {
                purchasedList[index].criterionTime = _criterionTime;
            }
        }
    }

    function releaseMany(address _product, bool release)
        external
        onlyOwner
        validAddress(_product)
    {
        //TODO require
        //release check
        //refund check
        //blockTime check

        for(uint index=0; index < purchasedList.length; index++) {
            if (purchasedList[index].product == _product) {
                purchasedList[index].release = release;
            }
        }
        //TODO token safeTransfer
    }

    function release(address _product)
        external
        validAddress(_product)
    {
        //TODO require
        //release check
        //refund check
        //blockTime check

        for(uint index=0; index < purchasedList.length; index++) {
            if (purchasedList[index].buyer == msg.sender
                && purchasedList[index].product == _product) {
                purchasedList[index].release = true;
                //TODO token safeTransfer
            }
        }
    }

    function refund(address _buyer, address _product, bool refund)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        //TODO require
        //release check

        for(uint index=0; index < purchasedList.length; index++) {
            if (purchasedList[index].buyer == _buyer
                && purchasedList[index].product == _product) {
                purchasedList[index].refund = refund;
            }
        }
    }
}
