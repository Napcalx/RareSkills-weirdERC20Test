// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {NotBasedRewarder, NotBasedToken} from "../src/based.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NotBasedRewarderTest is Test {
    NotBasedToken public rewardToken;
    NotBasedToken public depositToken;
    NotBasedRewarder public rewarder;

    address public owner = address(0x123);
    address public user = address(0x456);

    function setUp() public {
        // Deploy tokens and the rewarder contract
        vm.startPrank(owner);
        rewardToken = new NotBasedToken(owner);
        depositToken = new NotBasedToken(owner);

        rewarder = new NotBasedRewarder(
            IERC20(address(rewardToken)),
            IERC20(address(depositToken))
        );

        // Mint tokens for testing
        rewardToken.transfer(user, 1000 ether);
        depositToken.transfer(user, 100 ether);
        rewardToken.transfer(address(rewarder), 100 ether);

        vm.stopPrank();
        // User approves rewarder contract to spend their tokens
        vm.startPrank(user);
        depositToken.approve(address(rewarder), type(uint256).max);
        rewardToken.approve(address(rewarder), type(uint256).max);
        vm.stopPrank();

        // Make sure the contract has some balance after setup
        uint256 rewarderDepositTokenBalance = depositToken.balanceOf(
            address(rewarder)
        );
        uint256 rewarderRewardTokenBalance = rewardToken.balanceOf(
            address(rewarder)
        );
        console.log(
            "Rewarder Deposit Token Balance: ",
            rewarderDepositTokenBalance
        );
        console.log(
            "Rewarder Reward Token Balance: ",
            rewarderRewardTokenBalance
        );
    }

    function testCannotWithdrawWithout24Hours() public {
        vm.startPrank(user);

        // User deposits tokens
        rewarder.deposit(100 ether);

        // Attempt to withdraw before 24 hours
        vm.expectRevert();
        rewarder.withdraw(100 ether);

        // Fast forward time by 23 hours (not enough for bonus)
        vm.warp(block.timestamp + 23 hours);

        // Attempt to withdraw again
        vm.expectRevert();
        rewarder.withdraw(100 ether);

        vm.stopPrank();
    }

    function testWithdrawAfter24Hours() public {
        vm.startPrank(user);

        // User deposits tokens
        rewarder.deposit(100 ether);

        uint256 initialRewarderDepositBalance = depositToken.balanceOf(
            address(rewarder)
        );
        console.log(
            "Initial Rewarder Deposit Token Balance: ",
            initialRewarderDepositBalance
        );

        // uint256 userBalance = rewarder.internalBalances(user);
        // console.log("User's internal balance after deposit: ", userBalance);

        vm.stopPrank();

        // Fast forward time by 25 hours
        vm.warp(block.timestamp + 25 hours);

        // Withdraw after 24 hours
        vm.startPrank(user);
        rewarder.withdraw(100 ether);

        uint256 finalRewarderDepositBalance = depositToken.balanceOf(
            address(rewarder)
        );
        console.log(
            "Final Rewarder Deposit Token Balance: ",
            finalRewarderDepositBalance
        );

        // Verify balances after withdrawal
        assertEq(depositToken.balanceOf(user), 1000 ether);
        assertEq(rewardToken.balanceOf(user), 100 ether); // Bonus applied

        vm.stopPrank();
    }

    function testCannotWithdrawExcessAmount() public {
        vm.startPrank(user);

        // User deposits tokens
        rewarder.deposit(100 ether);

        // Attempt to withdraw more than deposited
        vm.expectRevert("insufficient balance");
        rewarder.withdraw(200 ether);

        vm.stopPrank();
    }

    function testCannotWithdrawDueToInsufficientBalance() public {
        vm.startPrank(user); // Simulate actions from the user

        // User deposits tokens into the rewarder contract
        rewarder.deposit(100 ether);

        // Fast forward time by 25 hours to simulate waiting period
        vm.warp(block.timestamp + 25 hours);

        // Try to withdraw tokens (this should fail due to insufficient balance)
        vm.expectRevert("insufficient balance"); // Expect the revert with this error message
        rewarder.withdraw(100 ether);

        vm.stopPrank();
    }
}
