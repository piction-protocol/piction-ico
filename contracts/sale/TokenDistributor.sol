pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "contracts/utils/ExtendsOwnable.sol";
import "./Product.sol";

contract TokenDistributor is ExtendsOwnable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        address buyer;
        address product;
        uint256 id;
        uint256 amount;
        uint256 etherAmount;
        bool release;
        bool refund;
    }

    ERC20 token;
    Purchased[] private purchasedList;
    uint256 private index;
    uint256 public criterionTime;

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
        uint256 etherAmount,
        bool release,
        bool refund
    );

    event ReleaseByCount(
        address product,
        uint256 request,
        uint256 succeed,
        uint256 remainder
    );

    event BuyerAddressTransfer(uint256 _id, address _from, address _to);

    event WithdrawToken(address to, uint256 amount);

    constructor(address _token) public {
        token = ERC20(_token);
        index = 0;
        criterionTime = 0;

        //for error check
        purchasedList.push(Purchased(0, 0, 0, 0, 0, true, true));
    }

    function setPurchased(address _buyer, address _product, uint256 _amount, uint256 _etherAmount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
        returns(uint256)
    {
        index = index.add(1);
        purchasedList.push(Purchased(_buyer, _product, index, _amount, _etherAmount, false, false));
        return index;

        emit Receipt(_buyer, _product, index, _amount, _etherAmount, false, false);
    }

    function addPurchased(uint256 _index, uint256 _amount, uint256 _etherAmount) external onlyOwner {
        require(_index != 0);

        if (isLive(_index)) {
            purchasedList[_index].amount = purchasedList[_index].amount.add(_amount);
            purchasedList[_index].etherAmount = purchasedList[_index].etherAmount.add(_etherAmount);

            emit Receipt(
                purchasedList[_index].buyer,
                purchasedList[_index].product,
                purchasedList[_index].id,
                _amount,
                _etherAmount,
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

    function getEtherAmount(uint256 _index) external view returns(uint256) {
        if (_index == 0) {
            return 0;
        }

        if (purchasedList[_index].release || purchasedList[_index].refund) {
            return 0;
        } else {
            return purchasedList[_index].etherAmount;
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

    function setCriterionTime(uint256 _criterionTime) external onlyOwner {
        require(_criterionTime > 0);

        criterionTime = _criterionTime;
    }

    function releaseByCount(address _product, uint256 _count)
        external
        onlyOwner
    {
        require(criterionTime != 0);

        uint256 succeed = 0;
        uint256 remainder = 0;

        for(uint i=1; i < purchasedList.length; i++) {
            if (isLive(i) && (purchasedList[i].product == _product)) {
                if (succeed < _count) {
                    Product product = Product(purchasedList[i].product);
                    require(block.timestamp >= criterionTime.add(product.lockup() * 1 days));
                    require(token.balanceOf(address(this)) >= purchasedList[i].amount);

                    purchasedList[i].release = true;
                    token.safeTransfer(purchasedList[i].buyer, purchasedList[i].amount);

                    succeed = succeed.add(1);

                    emit Receipt(
                        purchasedList[i].buyer,
                        purchasedList[i].product,
                        purchasedList[i].id,
                        purchasedList[i].amount,
                        purchasedList[i].etherAmount,
                        purchasedList[i].release,
                        purchasedList[i].refund);
                } else {
                    remainder = remainder.add(1);
                }
            }
        }

        emit ReleaseByCount(_product, _count, succeed, remainder);
    }

    function release(uint256 _index) external onlyOwner {
        require(_index != 0);
        require(criterionTime != 0);
        require(isLive(_index));

        Product product = Product(purchasedList[_index].product);
        require(block.timestamp >= criterionTime.add(product.lockup() * 1 days));
        require(token.balanceOf(address(this)) >= purchasedList[_index].amount);

        purchasedList[_index].release = true;
        token.safeTransfer(purchasedList[_index].buyer, purchasedList[_index].amount);

        emit Receipt(
            purchasedList[_index].buyer,
            purchasedList[_index].product,
            purchasedList[_index].id,
            purchasedList[_index].amount,
            purchasedList[_index].etherAmount,
            purchasedList[_index].release,
            purchasedList[_index].refund);
    }

    function refund(uint _index) external onlyOwner returns (bool, uint256) {
        if (isLive(_index)) {
            purchasedList[_index].refund = true;

            emit Receipt(
                purchasedList[_index].buyer,
                purchasedList[_index].product,
                purchasedList[_index].id,
                purchasedList[_index].amount,
                purchasedList[_index].etherAmount,
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
