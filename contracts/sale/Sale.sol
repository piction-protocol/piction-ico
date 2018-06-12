pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "./Product.sol"
import "./TokenDistributor.sol"
import "../utils/Stateable.sol";

contract Sale is Stateable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public wallet;
    Whitelist public whiteList;
    Product public product;
    TokenDistributor public tokenDistributor;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    modifier completed() {
        require(getState() == State.Completed);
        _;
    }

    modifier finalized() {
        require(getState() == State.Finalized);
        _;
    }

    constructor () public {

    }

    function setTokenDistributor(address _tokenDistributor) external onlyOwner validAddress(_tokenDistributor) {

    }

    function setProduct(address _product) external onlyOwner finalized validAddress(_product) {

    }

    function setWhitelist(address _whitelist) external onlyOwner validAddress(_whitelist) {

    }

    function setWallet(address _wallet) external onlyOwner validAddress(_wallet) {

    }

    function pause() external onlyOwner {

    }

    function start() external onlyOwner {

    }

    function complete() external onlyOwner {

    }

    function finalize() external onlyOwner {

    }

    function () external payable {

    }

    function collect() private {

    }

    function getPurchaseAmount(address _buyer, uint256 _amount) private view returns (uint256, uint256) {

    }

    function min(uint256 val1, uint256 val2) private pure returns (uint256){

    }

    function refund(address _buyerAddress) private validAddress(_buyerAddress) {

    }

    event Purchase(address indexed _buyer, uint256 _purchased, uint256 _refund, uint256 _tokens);

    event ChangeExternalAddress(address _addr, string _name);
    event BuyerAddressTransfer(address indexed _from, address indexed _to);

    event Refund(address indexed _to, uint256 _amount);
    event Fail(address indexed _addr, string _reason);

}
