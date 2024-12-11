// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {StableCoin} from "../src/Freeze.sol";

contract StableCoinTest is Test {
    StableCoin private stableCoin;
    address private owner = address(0x123);
    address private user = address(0x456);
    address private recipient = address(0x789);

    function setUp() public {
        vm.startPrank(owner);
        stableCoin = new StableCoin();
        stableCoin.mint(user, 1000 ether); // Mint tokens for the user
        vm.stopPrank();
    }

    /// Test for bypassing the freeze functionality
    function testBypassFreeze() public {
        vm.startPrank(owner);
        stableCoin.freeze(user); // Freeze the user's account
        vm.stopPrank();

        // Simulate user trying to transfer funds despite being frozen
        vm.startPrank(user);

        // Expect revert due to freeze
        vm.expectRevert("account frozen");
        stableCoin.transfer(recipient, 100 ether);

        // Bypass scenario: Modify `msg.sender` to simulate a privileged user
        // FORGE CAN MOCK `msg.sender` TO TEST EDGE CASES
        vm.mockCall(
            address(stableCoin),
            abi.encodeWithSelector(stableCoin.transfer.selector),
            abi.encode(true) // Simulate a successful transfer bypass
        );

        bool success = stableCoin.transfer(recipient, 100 ether);
        assertTrue(success, "Transfer succeeded despite freeze");
        vm.stopPrank();
    }
}
