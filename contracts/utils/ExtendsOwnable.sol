pragma solidity ^0.4.24;

contract ExtendsOwnable {

    mapping(address => bool) public owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRevoked(address indexed revokedOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function removeOwner(address owner) public onlyOwner {
        require(owner != address(0));
        require(msg.sender != owner);
        owners[owner] = false;
        emit OwnershipRevoked(owner);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}
