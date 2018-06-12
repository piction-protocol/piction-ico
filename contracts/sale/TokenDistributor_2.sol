pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../utils/Ownable.sol";

contract TokenDistributor is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        address buyer;
        uint256 amount;
        uint256 criterionTime;
        bool release;
    }

    ERC20 token;
    mapping (address => Purchased[]) purchasedList;

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
        purchasedList[_product].push(Purchased(_buyer, _amount, 0, false));
    }

    function getAmount(address _buyer, address _product)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
        returns(uint256)
    {
        //TODO require

        for(uint index=0; index < purchasedList[_product].length; index++) {
            if (purchasedList[_product][index].buyer == _buyer) {
                return purchasedList[_product][index].amount;
            }
        }
        return 0;
    }

    function setCriterionTime(address _product, uint256 _criterionTime)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        //TODO require
        for(uint index=0; index < purchasedList[_product].length; index++) {
            purchasedList[_product][index].criterionTime = _criterionTime;
        }
    }

    function releaseMany(address _product)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        //TODO require
        //release check
        //blockTime check

        for(uint index=0; index < purchasedList[_product].length; index++) {
            purchasedList[_product][index].release = true;
        }
        //TODO token safeTransfer
    }

    function release(address _product) external {
        //TODO require
        //release check
        //blockTime check

        for(uint index=0; index < purchasedList[_product].length; index++) {
            if (purchasedList[_product][index].buyer == msg.sender) {
                purchasedList[_product][index].release = true;
                //TODO token safeTransfer
            }
        }
    }
}
