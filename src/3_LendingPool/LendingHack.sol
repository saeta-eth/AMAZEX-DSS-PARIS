// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {USDC} from "./USDC.sol";

/**
 * @title LendingPool
 */
contract LendingHack {
    /*//////////////////////////////
    //    Add your hack below!    //
    //////////////////////////////*/

    USDC public usdc;
    address public owner;
    string public constant name = "LendingPool hack";

    /**
     * @dev Constructor that sets the owner of the contract
     * @param _usdc The address of the USDC contract to use
     * @param _owner The address of the owner of the contract
     */
    constructor(address _owner, address _usdc) {
        owner = _owner;
        usdc = USDC(_usdc);
    }

    function withdraw() external {
        require(msg.sender == owner, "not owner");

        usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
    }
}
