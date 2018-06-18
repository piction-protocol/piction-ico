pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Stateable is Ownable {
    enum State{Unknown, Preparing, Starting, Pausing, Finished}
    State state;

    event OnStateChange(string _state);

    constructor() public {
        state = State.Unknown;
    }

    modifier prepared() {
        require(getState() == State.Preparing);
        _;
    }

    modifier started() {
        require(getState() == State.Starting);
        _;
    }

    modifier paused() {
        require(getState() == State.Pausing);
        _;
    }

    modifier finished() {
        require(getState() == State.Finished);
        _;
    }

    function setState(State _state) internal {
        state = _state;
        emit OnStateChange(getKeyByValue(state));
    }

    function getState() public view returns (State) {
        return state;
    }

    function getKeyByValue(State _state) public pure returns (string) {
        if (State.Preparing == _state) return "Preparing";
        if (State.Starting == _state) return "Starting";
        if (State.Pausing == _state) return "Pausing";
        if (State.Finished == _state) return "Finished";
        return "";
    }
}
