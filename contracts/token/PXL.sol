pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "contracts/token/CustomToken.sol";
import "contracts/token/ContractReceiver.sol";
import "contracts/utils/ExtendsOwnable.sol";

/**
 * @title PXL implementation based on StandardToken ERC-20 contract.
 *
 * @author Charls Kim - <cs.kim@battleent.com>
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract PXL is StandardToken, CustomToken, ExtendsOwnable {
    using SafeMath for uint256;

    mapping (address => uint256) private lockup;

    // Token basic information
    string public constant name = "Pixel";
    string public constant symbol = "PXL";
    uint256 public constant decimals = 18;

    uint256 private transferableTime = 0;

    /**
     * @dev PXL constrcutor
     *
     * @param _address Transfer ownership address
     */
    constructor(uint256 _address) public {
        require(_address != address(0));

        transferOwnership(_address);
    }

    function() public payable {
        revert();
    }

    function isTransferable(address _account) public view returns (bool) {
        if(transferableTime > 0) {
            return (transferableTime.add(lockup[_account]) < block.timestamp);
        } else {
            return false;
        }
    }

    function setTransferableTime() external onlyOwner {
        require(transferableTime == 0);

        transferableTime = block.timestamp;
    }

    function getTransferableTime() external view returns (uint256) {
        return transferableTime;
    }

    /**
     * @dev Transfer tokens from one address to another
     *
     * @notice override transferFrom to block transaction when contract was locked.
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return A boolean that indicates if transfer was successful.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferable(_from) || owners[msg.sender]);
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Transfer token for a specified address
     *
     * @notice override transfer to block transaction when contract was locked.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return A boolean that indicates if transfer was successful.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferable(msg.sender) || owners[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferLockup(address _to, uint256 _value, uint256 _days) public onlyOwner returns (bool) {
        require(lockup[_to] == 0);
        
        lockup[_to] = _days * 1 days;

        return super.transfer(_to, _value);
    }

    function approveAndCall(address _to, uint256 _value, bytes _data) public returns (bool) {
        require(_to != address(0) && _to != address(this));
        require(balanceOf(msg.sender) >= _value);

        if(approve(_to, _value) && isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.receiveApproval(msg.sender, _value, address(this), _data);
            emit ApproveAndCall(msg.sender, _to, _value, _data);

            return true;
        }
    }

    /**
     * @dev Function to mint tokens
     * @param _amount The amount of tokens to mint.
     */
     function mint(uint256 _amount) onlyOwner external {
        super._mint(msg.sender, _amount);

        emit Mint(msg.sender, _amount);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _amount The amount of token to be burned.
     */
    function burn(uint256 _amount) onlyOwner external {
        super._burn(msg.sender, _amount);

        emit Burn(msg.sender, _amount);
    }

    function isContract(address _addr) private view returns (bool) {
        uint256 length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
        length := extcodesize(_addr)
        }
        return (length > 0);
    }

    function getLockup(address _account) public view returns (uint256) {
        return lockup[_account];
    }

    event Mint(address indexed _to, uint256 _amount);
    event Burn(address indexed _from, uint256 _amount);
}
