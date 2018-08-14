pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Whitelist.sol";

import "contracts/sale/TokenDistributor.sol";
import "contracts/utils/Stateable.sol";

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

    modifier checkStatus() {
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
        checkStatus
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
        checkStatus
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
        require(buyers[productAddress][buyer] < product.exceed());
        require(buyers[productAddress][buyer].add(amount) >= product.minimum());

        uint256 purchase;
        uint256 refund;
        (purchase, refund) = getPurchaseDetail(buyers[productAddress][buyer], amount, productAddress);

        if(purchase > 0) {
            wallet.transfer(purchase);
            tokenDistributor.addPurchased(buyer, productAddress, purchase.mul(product.rate()), purchase);
            weiRaised[productAddress] = weiRaised[productAddress].add(purchase);
            buyers[productAddress][buyer] = buyers[productAddress][buyer].add(purchase);
        }

        if(refund > 0) {
            buyer.transfer(refund);
        }

        if(weiRaised[productAddress] >= product.maxcap()) {
            setState(State.Finished);
        }

        emit Purchase(buyer, purchase, refund, purchase.mul(product.rate()));
    }

    function getPurchaseDetail(uint256 _raisedAmount, uint256 _amount, address _product)
        private
        view
        returns (uint256, uint256)
    {
        uint256 d1 = product.maxcap().sub(weiRaised[_product]);
        uint256 d2 = product.exceed().sub(_raisedAmount);
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

    function refund(uint256 _id, address _product, address _buyer)
        external
        onlyOwner
        payable
        validAddress(_product)
        validAddress(_buyer)
    {
        require(_id > 0);

        bool isRefund;
        uint256 refundAmount;
        (isRefund, refundAmount) = tokenDistributor.refund(_id, _product, _buyer);

        require(msg.value == refundAmount);
        require(isRefund && refundAmount > 0);

        _buyer.transfer(refundAmount);

        if(address(product) == _product
            && (getState() == State.Starting || getState() == State.Pausing))
        {
            weiRaised[_product] = weiRaised[_product].sub(refundAmount);
            buyers[_product][_buyer] = buyers[_product][_buyer].sub(refundAmount);
        }
    }

    function buyerAddressTransfer(uint256 _id, address _product, address _from, address _to)
        external
        onlyOwner
        validAddress(_product)
        validAddress(_from)
        validAddress(_to)
    {
        require(_id > 0);
        require(whiteList.whitelist(_from));
        require(whiteList.whitelist(_to));
        require(buyers[_product][_from] > 0);
        require(buyers[_product][_to] == 0);

        bool isChanged;
        uint256 transferAmount;
        (isChanged, transferAmount) = tokenDistributor.buyerAddressTransfer(_id, _from, _to);

        require(isChanged && transferAmount > 0);

        buyers[_product][_from] = buyers[_product][_from].sub(transferAmount);
        buyers[_product][_to] = buyers[_product][_to].add(transferAmount);
    }

    event Purchase(address indexed _buyer, uint256 _purchased, uint256 _refund, uint256 _tokens);
    event ChangeExternalAddress(address _addr, string _name);
}
