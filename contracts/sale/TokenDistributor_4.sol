pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../utils/Ownable.sol";

contract TokenDistributor_4 is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        bytes32 id;
        address buyer;
        address product;
        uint256 amount;
        uint256 criterionTime;
        bool release;
        bool refund;
    }

    ERC20 token;
    Purchased[] purchasedList;
    mapping (bytes32 => uint256) indexId;
    uint256 private nonce;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    event Receipt(
        bytes32 id,
        address buyer,
        address product,
        uint256 amount,
        uint256 criterionTime,
        bool release,
        bool refund
    );

    constructor(address _token) {
        token = ERC20(_token);
        nonce = 0;
    }

    function addPurchased(address _buyer, address _product, uint256 _amount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        //TODO require

        nonce = nonce.add(1);
        bytes32 id = keccak256(msg.sender, block.timestamp, nonce);
        purchasedList.push(Purchased(id, _buyer, _product, _amount, 0, false, false));
        indexId[id] = purchasedList.length.sub(1);

        emit Receipt(id, _buyer, _product, _amount, 0, false, false);
    }

    function addPurchased(bytes32 _id, uint256 _amount) external onlyOwner {
        uint index = indexId[_id];
        if (!purchasedList[index].release || !purchasedList[index].refund) {
            purchasedList[index].amount = purchasedList[index].amount.add(_amount);
        }
    }

    function getAmount(bytes32 _id) external returns(uint256) {
        if (_id == 0) {
            return 0;
        }

        uint index = indexId[_id];
        if (purchasedList[index].release || purchasedList[index].refund) {
            return 0;
        } else {
            return purchasedList[index].amount;
        }
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

    function releaseProduct(address _product)
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
                purchasedList[index].release = true;

                //TODO token safeTransfer

                emit Receipt(
                    purchasedList[index].id,
                    purchasedList[index].buyer,
                    purchasedList[index].product,
                    purchasedList[index].amount,
                    purchasedList[index].criterionTime,
                    purchasedList[index].release,
                    purchasedList[index].refund);
            }
        }
    }

    function release(bytes32 _id) external onlyOwner {

        //TODO require
        //release check
        //refund check
        //blockTime check

        uint index = indexId[_id];
        if (!purchasedList[index].release || !purchasedList[index].refund) {
            purchasedList[index].release = true;

            //TODO token safeTransfer

            emit Receipt(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                purchasedList[index].amount,
                purchasedList[index].criterionTime,
                purchasedList[index].release,
                purchasedList[index].refund);
        }
    }

    function release(bytes32 _id) external onlyOwner {
        //TODO require
        //release check
        //refund check
        //blockTime check

        uint index = indexId[_id];
        if (!purchasedList[index].release || !purchasedList[index].refund) {
            purchasedList[index].release = true;
        }
        //TODO token safeTransfer
    }

    function refund(bytes32 _id) external onlyOwner returns (bool, uint256) {
        //TODO require
        //release check
        //refund check
        //blockTime check

        uint index = indexId[_id];
        if (!purchasedList[index].release || !purchasedList[index].refund) {
            purchasedList[index].refund = true;

            emit Receipt(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                purchasedList[index].amount,
                purchasedList[index].criterionTime,
                purchasedList[index].release,
                purchasedList[index].refund);

            return (true, purchasedList[index].amount);
        } else {
            return (false, 0);
        }
        //TODO token safeTransfer
    }
}
