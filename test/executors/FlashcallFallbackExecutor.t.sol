// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import {
    RhinestoneModuleKit,
    RhinestoneModuleKitLib,
    RhinestoneAccount
} from "modulekit/test/utils/biconomy-base/RhinestoneModuleKit.sol";
import { ExecutorTemplate } from "../../src/executors/ExecutorTemplate.sol";
import { FlashcallFallbackExecutor } from "../../src/executors/FlashcallFallbackExecutor.sol";
import { MockERC20 } from "forge-std/mocks/MockERC20.sol";
import { IERC3156FlashLender } from "openzeppelin-contracts/contracts/interfaces/IERC3156FlashLender.sol";
import { IERC3156FlashBorrower } from "openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import { ERC20ModuleKit } from "modulekit/modulekit/integrations/ERC20Actions.sol";
import { ExecutorAction } from "modulekit/modulekit/IExecutor.sol";
import { IPoolV3 } from "modulekit/modulekit/integrations/interfaces/aaveV3/IPoolV3.sol";
import { MockedPool } from "../mocked/MockedPool.sol";

contract MockedLender is IERC3156FlashLender {

    MockERC20 token;

    constructor(address _token) {
        token = MockERC20(_token);
    }
    
    function maxFlashLoan(address _token) external override view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function flashFee(address token, uint256 amount) external override view returns (uint256) {
        return 1;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address _token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        token.transfer(address(receiver), amount);
        uint256 fee = 1;
        receiver.onFlashLoan(
            msg.sender,
            address(token),
            amount,
            fee,
            data
        );
        token.transferFrom(address(receiver), address(this), amount+fee);
    }

}


contract FlashcallFallbackExecutorTest is Test, RhinestoneModuleKit {
    using RhinestoneModuleKitLib for RhinestoneAccount;

    RhinestoneAccount instance;
    FlashcallFallbackExecutor flashcallFallbackExecutor;
    MockERC20 token;
    MockedLender flashloanLender;
    IPoolV3 aavePool;

    function setUp() public {
        // Setup account
        instance = makeRhinestoneAccount("1");
        vm.deal(instance.account, 10 ether);
        vm.label(instance.account, "account");


        token = new MockERC20();
        token.initialize("Mock Token", "MTK", 18);

        vm.deal(instance.account, 100 ether);

        console2.log("account address", instance.account);

        flashloanLender = new MockedLender(address(token));
        deal(address(token), address(flashloanLender), 1000000);
        vm.label(address(flashloanLender), "flashloanLender");

        aavePool = new MockedPool(address(token));
        deal(address(token), address(aavePool), 1000000);
        vm.label(address(aavePool), "aavePool");


        // token.mint(address(flashloanLender), 1000000);

        // Setup executor
        flashcallFallbackExecutor = new FlashcallFallbackExecutor(
            instance.fallbackHandler,
            address(token),
            address(flashloanLender),
            address(aavePool)
        );

        vm.label(address(flashcallFallbackExecutor), "flashcallFallbackExecutor");

        // Add executor to account
        instance.addExecutor(address(flashcallFallbackExecutor));


        instance.addFallback({
            handleFunctionSig: IERC3156FlashBorrower.onFlashLoan.selector,
            isStatic: false,
            handler: address(flashcallFallbackExecutor)
        });

    }

    function testExecuteAction() public {
        // Create target and ensure that it doesnt have a balance
        address target = makeAddr("target");
        assertEq(target.balance, 0);
        assertEq(token.balanceOf(instance.account), 0);

        vm.prank(instance.account);
        bytes memory origCalldata = abi.encodeWithSelector(token.transfer.selector, target, 123);
        bytes memory prependedCalldata = abi.encode(instance.aux.executorManager, address(token), origCalldata);
        flashloanLender.flashLoan(
            IERC3156FlashBorrower(instance.account),
            address(token),
            1000,
            prependedCalldata
        );
        
        // Assert that target has a balance of 1 wei
        assertEq(token.balanceOf(target), 123);
        assertEq(token.balanceOf(instance.account), 0);
    }
}
