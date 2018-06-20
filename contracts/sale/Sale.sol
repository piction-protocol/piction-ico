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

    mapping (address => bool) isRegistered;
    mapping (address => uint256) weiRaised;
    mapping (address => mapping (address => uint256)) buyers;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    modifier validProductAddress(address _product) {
        require(!isRegistered[_product]);
        _;
    }

    modifier changeProduct() {
        require(getState() == State.Unknown || getState() == State.Preparing || getState() == State.Finished);
        _;
    }

    constructor (
        address _wallet,
        address _whiteList,
        address _tokenDistributor
    ) public {
        require(_wallet != address(0));
        require(_whiteList != address(0));
        require(_tokenDistributor != address(0));

        wallet = _wallet;
        whiteList = Whitelist(_whiteList);
        tokenDistributor = TokenDistributor(_tokenDistributor);
    }

    function registerProduct(address _product)
        external
        onlyOwner
        changeProduct
        validAddress(_product)
        validProductAddress(_product)
    {
        product = Product(_product);

        require(product.maxcap() > product.minimum());

        isRegistered[_product] = true;

        setState(State.Preparing);

        emit ChangeExternalAddress(_product, "Product");
    }

    function setTokenDistributor(address _tokenDistributor)
        external
        onlyOwner
        validAddress(_tokenDistributor)
    {
        tokenDistributor = TokenDistributor(_tokenDistributor);
        emit ChangeExternalAddress(_tokenDistributor, "TokenDistributor");
    }

    function setWhitelist(address _whitelist)
        external
        onlyOwner
        validAddress(_whitelist)
    {
        whiteList = Whitelist(_whitelist);
        emit ChangeExternalAddress(_whitelist, "Whitelist");
    }

    function setWallet(address _wallet)
        external
        onlyOwner
        validAddress(_wallet)
    {
        wallet = _wallet;
        emit ChangeExternalAddress(_wallet, "Wallet");
    }

    function pause() external onlyOwner {
        require(getState() == State.Starting);

        setState(State.Pausing);
    }

    function start() external onlyOwner {
        require(getState() == State.Preparing || getState() == State.Pausing);

        setState(State.Starting);
    }

    function finish() external onlyOwner {
        setState(State.Finished);
    }

    function () external payable {
        address buyer = msg.sender;
        uint256 amount = msg.value;
        address productAddress = address(product);

        require(getState() == State.Starting);
        require(whiteList.whitelist(buyer));
        require(buyer != address(0));
        require(weiRaised[productAddress] < product.maxcap());

        uint256 buyerAmount = tokenDistributor.getEtherAmount(buyers[productAddress][buyer]);

        require(buyerAmount < product.exceed());
        require(buyerAmount.add(amount) >= product.minimum());

        uint256 purchase;
        uint256 refund;
        (purchase, refund) = getPurchaseDetail(buyerAmount, amount, productAddress);

        if(buyerAmount > 0) {
            tokenDistributor.addPurchased(buyers[productAddress][buyer], purchase.mul(product.rate()), purchase);
        } else {
            buyers[productAddress][buyer] = tokenDistributor.setPurchased(buyer, productAddress, purchase.mul(product.rate()), purchase);
        }

        wallet.transfer(purchase);

        if(refund > 0) {
            buyer.transfer(refund);
        }

        weiRaised[productAddress] = weiRaised[productAddress].add(purchase);

        if(weiRaised[productAddress] >= product.maxcap()) {
            setState(State.Finished);
        }

        emit Purchase(buyer, purchase, refund, purchase.mul(product.rate()));
    }

    function getPurchaseDetail(uint256 _buyerAmount, uint256 _amount, address _product)
        private
        view
        returns (uint256, uint256)
    {
        uint256 d1 = product.maxcap().sub(weiRaised[_product]);
        uint256 d2 = product.exceed().sub(_buyerAmount);
        uint256 possibleAmount = (d1.min256(d2)).min256(_amount);

        return (possibleAmount, _amount.sub(possibleAmount));
    }

    function getProductWeiRaised(address _product)
        external
        view
        validAddress(_product)
        returns (uint256)
    {
        return weiRaised[_product];
    }

    function refund(address _product, address _buyer)
        external
        onlyOwner
        validAddress(_product)
        validAddress(_buyer)
    {
        require(buyers[_product][_buyer] > 0);

        bool isRefund;
        uint256 refundAmount;
        (isRefund, refundAmount) = tokenDistributor.refund(buyers[_product][_buyer]);

        require(refundAmount > 0);

        if(isRefund) {
            weiRaised[_product] = weiRaised[_product].sub(refundAmount);
            delete buyers[_product][_buyer];
        }
    }

    function buyerAddressTransfer(address _product, address _from, address _to)
        external
        onlyOwner
        validAddress(_product)
        validAddress(_from)
        validAddress(_to)
    {
        require(whiteList.whitelist(_from));
        require(whiteList.whitelist(_to));
        require(tokenDistributor.getEtherAmount(buyers[_product][_from]) > 0);
        require(tokenDistributor.getEtherAmount(buyers[_product][_to]) == 0);

        bool isChanged = tokenDistributor.buyerAddressTransfer(buyers[_product][_from], _from, _to);

        require(isChanged);

        uint256 fromId = buyers[_product][_from];
        buyers[_product][_to] = fromId;
        delete buyers[_product][_from];

        emit BuyerAddressTransfer(_from, _to, buyers[_product][_to]);
    }

    event Purchase(address indexed _buyer, uint256 _purchased, uint256 _refund, uint256 _tokens);
    event ChangeExternalAddress(address _addr, string _name);
    event BuyerAddressTransfer(address indexed _from, address indexed _to, uint256 _id);
}
