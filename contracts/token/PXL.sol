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

    // PXL 세일 참여자 락업 기간 설정 매핑 변수(참여자 주소 => 락업 기간(sec))
    mapping (address => uint256) private lockup;

    // PXL 토큰 기본 정보
    string public constant name = "Pixel";
    string public constant symbol = "PXL";
    uint256 public constant decimals = 18;

    // 상장 시간(초 단위로 설정)
    uint256 private transferableTime = 0;

    function() public payable {
        revert();
    }

    /**
     * @dev 토큰 전송 가능 여부 확인 함수
     *
     * @notice 상장이전 토큰 전송 불가
     * @notice 토큰 세일 참여자 별 별도의 락업 기간을 확인
     * @param _account 개인 참여자 지갑 주소
     * @return 토큰 전송 가능 여부 bool 값
     */
    function isTransferable(address _account) public view returns (bool) {
        if(transferableTime > 0) {
            return (transferableTime.add(lockup[_account]) < block.timestamp);
        } else {
            return false;
        }
    }

    /**
     * @dev 거래소 상장 시간 등록 함수
     *
     * @notice 거래소 상장 시간은 최초 한번만 등록 가능
     */
    function setTransferableTime() external onlyOwner {
        require(transferableTime == 0);

        transferableTime = block.timestamp;
    }

    /**
     * @dev 거래소 상장 시간 확인 함수
     *
     * @notice 거래소 상장 시간은 최초 한번만 등록 가능
     * @return uint256 타입의 상장 시간(초)
     */
    function getTransferableTime() external view returns (uint256) {
        return transferableTime;
    }

    /**
     * @dev 토큰 대리 전송을 위한 함수
     *
     * @notice 토큰 전송이 불가능 할 경우 전송 실패
     * @param _from 토큰을 가지고 있는 지갑 주소
     * @param _to 대리 전송 권한을 부여할 지갑 주소
     * @param _value 대리 전송할 토큰 수량
     * @return bool 타입의 토큰 대리 전송 권한 성공 여부
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferable(_from) || owners[msg.sender]);
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev PXL 토큰 전송 함수
     *
     * @notice 토큰 전송이 불가능 할 경우 전송 실패
     * @param _to 토큰을 받을 지갑 주소
     * @param _value 전송할 토큰 수량
     * @return bool 타입의 전송 결과
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferable(msg.sender) || owners[msg.sender]);
        return super.transfer(_to, _value);
    }

    /**
     * @dev PXL sale 참여자의 락업 기간 설정 함수
     *
     * @notice 지갑 주소 하나 당 하나의 sale만 참여 가능
     * @notice 참여자의 토큰은 전송하며 락업 기간 설정
     * @param _to sale 참여자 주소
     * @param _value 토큰 구매 수량
     * @return bool 타입의 토큰 구매 결과
     */
    function transferAndLockup(address _to, uint256 _value, uint256 _days) public onlyOwner returns (bool) {
        require(lockup[_to] == 0);

        setLockup(_to, _days);
        return super.transfer(_to, _value);
    }

    /**
     * @dev PXL 전송과 데이터를 함께 사용하는 함수
     *
     * @notice CustomToken 인터페이스 활용
     * @notice _to 주소가 컨트랙트인 경우만 사용 가능
     * @notice 토큰과 데이터를 받으려면 해당 컨트랙트에 receiveApproval 함수 구현 필요
     * @param _to 토큰을 전송하고 함수를 실행할 컨트랙트 주소
     * @param _value 전송할 토큰 수량
     * @return bool 타입의 처리 결과
     */
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
     * @dev 토큰 발행 함수
     * @param _amount 발행할 토큰 수량
     */
     function mint(uint256 _amount) onlyOwner external {
        super._mint(msg.sender, _amount);

        emit Mint(msg.sender, _amount);
    }

    /**
     * @dev 토큰 소멸 함수
     * @param _amount 소멸할 토큰 수량
     */
    function burn(uint256 _amount) onlyOwner external {
        super._burn(msg.sender, _amount);

        emit Burn(msg.sender, _amount);
    }

    /**
     * @dev 컨트랙트 확인 함수
     * @param _addr 컨트랙트 주소
     */
    function isContract(address _addr) private view returns (bool) {
        uint256 length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    /**
     * @dev 개인 주소 잠금 기간 확인 함수
     * @param _account 개인 지갑 주소
     * @return uint256 계정 잠금 시간(초)
     */
    function getLockup(address _account) public view returns (uint256) {
        return lockup[_account];
    }

    /**
     * @dev 개인 주소 잠금 기간 설정 함수
     * @param _address 개인 지갑 주소
     * @param _days 잠금 시간(일)
     */
    function setLockup(address _address, uint256 _days) public onlyOwner {
        lockup[_address] = _days * 1 days;

        emit Lockup(_address, _days);
    }

    event Mint(address indexed _to, uint256 _amount);
    event Burn(address indexed _from, uint256 _amount);
    event Lockup(address indexed _account, uint256 _days);
}
