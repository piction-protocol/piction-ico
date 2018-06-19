pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Product.sol";

contract TokenDistributor is ExtendsOwnable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        address buyer;
        address product;
        uint256 id;
        uint256 amount;
        bool release;
        bool refund;
    }

    ERC20 token;
    Purchased[] public purchasedList;
    uint256 index;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    event Receipt(
        address buyer,
        address product,
        uint256 id,
        uint256 amount,
        bool release,
        bool refund
    );

    event BuyerAddressTransfer(uint256 _id, address _from, address _to);

    event WithdrawToken(address to, uint256 amount);

    constructor(address _token) public {
        token = ERC20(_token);
        index = 0;

        //for error check
        purchasedList.push(Purchased(0, 0, 0, 0, true, true));
    }

    function setPurchased(address _buyer, address _product, uint256 _amount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
        returns(uint256)
    {
        index = index.add(1);
        purchasedList.push(Purchased(_buyer, _product, index, _amount, 0, false, false));
        return index;

        emit Receipt(_buyer, _product, index, _amount, false, false);
    }

    function addPurchased(uint256 _index, uint256 _amount) external onlyOwner {
        require(_index != 0);

        if (isLive(_index)) {
            purchasedList[_index].amount = purchasedList[_index].amount.add(_amount);

            emit Receipt(
                purchasedList[_index].buyer,
                purchasedList[_index].product,
                purchasedList[_index].id,
                _amount,
                false,
                false);
        }
    }

    function getAmount(uint256 _index) external view returns(uint256) {
        if (_index == 0) {
            return 0;
        }

        if (purchasedList[_index].release || purchasedList[_index].refund) {
            return 0;
        } else {
            return purchasedList[_index].amount;
        }
    }

    function getId(address _buyer, address _product) external view returns (uint256) {
        for(uint i=1; i < purchasedList.length; i++) {
            if (purchasedList[i].product == _product
                && purchasedList[i].buyer == _buyer) {
                return purchasedList[i].id;
            }
        }
        return 0;
    }

    function releaseProduct(address _product)
        external
        onlyOwner
        validAddress(_product)
    {
        for(uint i=1; i < purchasedList.length; i++) {
            if (purchasedList[i].product == _product
                && !purchasedList[i].release
                && !purchasedList[i].refund)
            {
                Product product = Product(purchasedList[i].product);
                require(product.criterionTime != 0);
                require(block.timestamp >= product.criterionTime.add(product.lockup() * 1 days));
                purchasedList[i].release = true;

                require(token.balanceOf(address(this)) >= purchasedList[i].amount);
                token.safeTransfer(purchasedList[i].buyer, purchasedList[i].amount);

                emit Receipt(
                    purchasedList[i].buyer,
                    purchasedList[i].product,
                    purchasedList[i].id,
                    purchasedList[i].amount,
                    purchasedList[i].release,
                    purchasedList[i].refund);
            }
        }
    }

    function release(uint256 _index) external onlyOwner {
        if (isLive(_index)) {
            Product product = Product(purchasedList[_index].product);
            require(product.criterionTime != 0);
            require(block.timestamp >= product.criterionTime.add(product.lockup() * 1 days));
            purchasedList[_index].release = true;

            require(token.balanceOf(address(this)) >= purchasedList[_index].amount);
            token.safeTransfer(purchasedList[_index].buyer, purchasedList[_index].amount);

            emit Receipt(
                purchasedList[_index].buyer,
                purchasedList[_index].product,
                purchasedList[_index].id,
                purchasedList[_index].amount,
                purchasedList[_index].release,
                purchasedList[_index].refund);
        }
    }

    function refund(uint _index) external onlyOwner returns (bool, uint256) {
        if (isLive(_index)) {
            Product product = Product(purchasedList[_index].product);
            purchasedList[_index].refund = true;

            emit Receipt(
                purchasedList[_index].buyer,
                purchasedList[_index].product,
                purchasedList[_index].id,
                purchasedList[_index].amount,
                purchasedList[_index].release,
                purchasedList[_index].refund);

            return (true, purchasedList[_index].amount);
        } else {
            return (false, 0);
        }
    }

    function buyerAddressTransfer(uint256 _index, address _from, address _to)
        external
        onlyOwner
        returns (bool)
    {
        if (purchasedList[_index].buyer == _from) {
            purchasedList[_index].buyer = _to;
            emit BuyerAddressTransfer(_index, _from, _to);
            return true;
        } else {
            return false;
        }
    }

    function withdrawToken(address _Owner) external onlyOwner {
        token.safeTransfer(_Owner, token.balanceOf(address(this)));
        emit WithdrawToken(_Owner, token.balanceOf(address(this)));
    }

    function isLive(uint256 _index) private view returns(bool){
        if (!purchasedList[_index].release && !purchasedList[_index].refund) {
            return true;
        } else {
            return false;
        }
    }
}
