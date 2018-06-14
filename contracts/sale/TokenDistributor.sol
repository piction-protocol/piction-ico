pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Product.sol";

contract TokenDistributor is Ownable {

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

    event ReceiptList(
        bytes32 id,
        address buyer,
        address product,
        uint256 amount,
        uint256 criterionTime,
        bool release,
        bool refund
    );

    event BuyerAddressTransfer(bytes32 _id, address _from, address _to);

    event WithdrawToken(address to, uint256 amount);

    constructor(address _token) public {
        token = ERC20(_token);
        nonce = 0;

        //for error check
        purchasedList.push(Purchased(0, 0, 0, 0, 0, true, true));
    }

    function addPurchased(address _buyer, address _product, uint256 _amount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
    {
        nonce = nonce.add(1);
        bytes32 id = keccak256(_buyer, block.timestamp, nonce);
        purchasedList.push(Purchased(id, _buyer, _product, _amount, 0, false, false));
        indexId[id] = purchasedList.length;

        emit Receipt(id, _buyer, _product, _amount, 0, false, false);
    }

    function addPurchased(bytes32 _id, uint256 _amount) external onlyOwner {
        require(_id != 0);

        uint index = indexId[_id];
        if (!purchasedList[index].release || !purchasedList[index].refund) {
            purchasedList[index].amount = purchasedList[index].amount.add(_amount);
        }
    }

    function getAmount(bytes32 _id) external view returns(uint256) {
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

    function getPurchasedList() external onlyOwner {
        for(uint index=1; index < purchasedList.length; index++) {
            emit ReceiptList(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                purchasedList[index].amount,
                purchasedList[index].criterionTime,
                purchasedList[index].release,
                purchasedList[index].refund);
        }
    }

    function setCriterionTime(address _product, uint256 _criterionTime)
        external
        onlyOwner
        validAddress(_product)
    {
        for(uint index=1; index < purchasedList.length; index++) {
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
        for(uint index=1; index < purchasedList.length; index++) {
            if (purchasedList[index].product == _product
                && !purchasedList[index].release
                && !purchasedList[index].refund)
            {
                Product product = Product(purchasedList[index].product);
                require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
                purchasedList[index].release = true;

                require(token.balanceOf(address(this)) >= purchasedList[index].amount);
                token.safeTransfer(purchasedList[index].buyer, purchasedList[index].amount);

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
        uint index = indexId[_id];
        if (!purchasedList[index].release && !purchasedList[index].refund) {

            Product product = Product(purchasedList[index].product);
            require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
            purchasedList[index].release = true;

            require(token.balanceOf(address(this)) >= purchasedList[index].amount);
            token.safeTransfer(purchasedList[index].buyer, purchasedList[index].amount);

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

    function refund(bytes32 _id) external onlyOwner returns (bool, uint256) {
        uint index = indexId[_id];
        if (!purchasedList[index].release && !purchasedList[index].refund) {
            Product product = Product(purchasedList[index].product);
            require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
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
    }

    function buyerAddressTransfer(bytes32 _id, address _from, address _to)
        external
        onlyOwner
        returns (bool)
    {
        uint index = indexId[_id];
        if (purchasedList[index].buyer == _from) {
            purchasedList[index].buyer = _to;
            emit BuyerAddressTransfer(_id, _from, _to);
            return true;
        } else {
            return false;
        }
    }

    function withdrawToken(address _Owner) external onlyOwner {
        token.safeTransfer(_Owner, token.balanceOf(address(this)));
        emit WithdrawToken(_Owner, token.balanceOf(address(this)));
    }
}
