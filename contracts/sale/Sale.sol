pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "./Product.sol"
import "./TokenDistributor.sol"
import "../utils/Stateable.sol";
import "../utils/PixelMath.sol";

contract Sale is Stateable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public wallet;
    Whitelist public whiteList;
    Product public product;
    TokenDistributor public tokenDistributor;

    mapping (address => bytes32) buyers;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    modifier limit(address[] _addrs) {
        require(_addrs.length <= 30);
        _;
    }

    modifier changeProduct() {
        require(getState() == State.Preparing || getState() == State.finished);
        _;
    }


    constructor (
        address _wallet,
        address _whiteList,
        address _product,
        address _tokenDistributor
    ) public {
        require(_wallet != address(0));
        require(_whiteList != address(0));
        require(_product != address(0));
        require(_tokenDistributor != address(0));

        wallet = _wallet;
        whiteList = Whitelist(_whiteList);
        product = Product(_product);
        tokenDistributor = TokenDistributor(_tokenDistributor);

        setState(State.Preparing);
    }

    function registerProduct(address _product) external onlyOwner changeProduct validAddress(_product) {
        delete buyers;
        setState(State.Preparing);
        product = Product(_product);

        emit ChangeExternalAddress(_product, "Product");
    }

    function setTokenDistributor(address _tokenDistributor) external onlyOwner validAddress(_tokenDistributor) {
        tokenDistributor = TokenDistributor(_tokenDistributor);
        emit ChangeExternalAddress(_product, "TokenDistributor");
    }

    function setWhitelist(address _whitelist) external onlyOwner validAddress(_whitelist) {
        whiteList = Whitelist(_whitelist);
        emit ChangeExternalAddress(_whitelist, "Whitelist");
    }

    function setWallet(address _wallet) external onlyOwner validAddress(_wallet) {
        wallet = _wallet;
        emit ChangeExternalAddress(_wallet, "Wallet");
    }

    function pause() external onlyOwner {
        setState(State.Pausing);
    }

    function start() external onlyOwner {
        setState(State.Starting);
    }

    function finished() external onlyOwner {
        setState(State.finished);
    }

    function () external payable {
        address buyer = msg.sender;
        uint256 amount = msg.value;

        require(getState() == State.Starting);
        require(whiteList.whitelist(buyer));
        require(buyer != address(0));
        require(product.weiRaised < product.maxcap);

        address productAddress = address(product);
        uint256 tokenAmount = tokenDistributor.getAmount(buyers[buyer]);
        uint256 buyerAmount = (tokenAmount > 0) ? tokenAmount.div(product.rate) : 0 ;

        require(buyerAmount < product.exceed);
        require(buyerAmount.add(amount) >= product.minimum);

        uint256 purchase;
        uint256 refund;
        uint256 totalAmount;
        (purchase, refund, totalAmount) = getPurchaseDetail(buyer, amount, buyerAmount);

        product.addWeiRaised(totalAmount);

        if(buyerAmount > 0) {
            tokenDistributor.addPurchased(buyers[buyer], totalAmount.mul(product.rate));
        } else {
            tokenDistributor.addPurchased(buyer, productAddress, totalAmount.mul(product.rate));
        }

        wallet.transfer(purchase);

        if(refund > 0) {
            buyer.transfer(refund);
        }

        if(totalAmount >= product.maxcap) {
            setState(state.finished);
        }

        emit Purchase(buyer, purchase, refund, purchase.mul(rate));
    }

    function getPurchaseDetail(address _buyer, uint256 _amount, uint256 _buyerAmount) private view returns (uint256, uint256, uint256) {
        uint256 d1 = product.maxcap.sub(product.weiRaised);
        uint256 d2 = product.exceed.sub(_buyerAmount);
        uint256 possibleAmount = min(min(d1, d2), _amount);

        return (possibleAmount, _amount.sub(possibleAmount), possibleAmount.add(product.weiRaised));
    }

    function refund(address _buyerAddress) private validAddress(_buyerAddress) {
        bool isRefund;
        uint256 refundAmount;
        (isRefund, refundAmount) = tokenDistributor.refund(_buyerAddress, address(product));

        if(isRefund) {
            product.subWeiRaised(refundAmount);
            delete buyers[_buyerAddress];
        }
    }

    event Purchase(address indexed _buyer, uint256 _purchased, uint256 _refund, uint256 _tokens);
    event ChangeExternalAddress(address _addr, string _name);
    event BuyerAddressTransfer(address indexed _from, address indexed _to);
}
