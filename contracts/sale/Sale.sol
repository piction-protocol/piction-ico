pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Whitelist.sol";

import "./TokenDistributor.sol";
import "../utils/Stateable.sol";

contract Sale is Stateable {
    using SafeMath for uint256;
    using Math for uint256;

    address public wallet;
    Whitelist public whiteList;
    Product public product;
    TokenDistributor public tokenDistributor;

    mapping (string => mapping (address => bytes32)) buyers;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    modifier validProductName(string _productName) {
        require(bytes(_productName).length != 0);
        _;
    }

    modifier changeProduct() {
        require(getState() == State.Preparing || getState() == State.Finished);
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
        product = Product(_product);

        require(buyers[product.name()] != 0);

        setState(State.Preparing);

        emit ChangeExternalAddress(_product, "Product");
    }

    function setTokenDistributor(address _tokenDistributor) external onlyOwner validAddress(_tokenDistributor) {
        tokenDistributor = TokenDistributor(_tokenDistributor);
        emit ChangeExternalAddress(_tokenDistributor, "TokenDistributor");
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

    function finish() external onlyOwner {
        setState(State.Finished);
    }

    function () external payable {
        address buyer = msg.sender;
        uint256 amount = msg.value;

        require(getState() == State.Starting);
        require(whiteList.whitelist(buyer));
        require(buyer != address(0));
        require(product.weiRaised() < product.maxcap());

        address productAddress = address(product);
        uint256 tokenAmount = tokenDistributor.getAmount(buyers[product.name()][buyer]);
        uint256 buyerAmount = (tokenAmount > 0) ? tokenAmount.div(product.rate()) : 0 ;

        require(buyerAmount < product.exceed());
        require(buyerAmount.add(amount) >= product.minimum());

        uint256 purchase;
        uint256 refund;
        uint256 totalAmount;
        (purchase, refund, totalAmount) = getPurchaseDetail(buyerAmount, amount);

        product.addWeiRaised(totalAmount);

        if(buyerAmount > 0) {
            tokenDistributor.addPurchased(buyers[product.name()][buyer], purchase.mul(product.rate()));
        } else {
            tokenDistributor.addPurchased(buyer, productAddress, purchase.mul(product.rate()));
        }

        wallet.transfer(purchase);

        if(refund > 0) {
            buyer.transfer(refund);
        }

        if(totalAmount >= product.maxcap()) {
            setState(State.Finished);
        }

        emit Purchase(buyer, purchase, refund, purchase.mul(product.rate()));
    }

    function getPurchaseDetail(uint256 _buyerAmount, uint256 _amount) private view returns (uint256, uint256, uint256) {
        uint256 d1 = product.maxcap().sub(product.weiRaised());
        uint256 d2 = product.exceed().sub(_buyerAmount);
        uint256 possibleAmount = (d1.min256(d2)).min256(_amount);

        return (possibleAmount, _amount.sub(possibleAmount), possibleAmount.add(product.weiRaised()));
    }

    function refund(string _productName, address _buyerAddress) external onlyOwner validProductName(_productName) validAddress(_buyerAddress) {
        bool isRefund;
        uint256 refundAmount;
        (isRefund, refundAmount) = tokenDistributor.refund(buyers[_productName][_buyerAddress]);

        if(isRefund) {
            product.subWeiRaised(refundAmount);
            delete buyers[_productName][_buyerAddress];
        }
    }

    function buyerAddressTransfer(string _productName, address _from, address _to) external onlyOwner validProductName(_productName) validAddress(_from) validAddress(_to) {
        require(whiteList.whitelist(_from));
        require(whiteList.whitelist(_to));
        require(tokenDistributor.getAmount(buyers[_productName][_from]) > 0);
        require(tokenDistributor.getAmount(buyers[_productName][_to]) == 0);

        bool isChanged = tokenDistributor.buyerAddressTransfer(buyers[_productName][_from], _from, _to);

        require(isChanged);

        bytes32 fromId = buyers[_productName][_from];
        buyers[_productName][_to] = fromId;
        delete buyers[_productName][_from];

        emit BuyerAddressTransfer(_from, _to, buyers[_productName][_to]);
    }

    event Purchase(address indexed _buyer, uint256 _purchased, uint256 _refund, uint256 _tokens);
    event ChangeExternalAddress(address _addr, string _name);
    event BuyerAddressTransfer(address indexed _from, address indexed _to, bytes32 _id);
}
