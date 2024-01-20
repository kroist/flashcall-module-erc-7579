// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import "modulekit/ModuleKit.sol";
import "modulekit/Modules.sol";
import "modulekit/Helpers.sol";
import "modulekit/Mocks.sol";
import { FlashcallFallbackExecutor } from "../../src/executors/FlashcallFallbackExecutor.sol";
import { MockERC20 } from "forge-std/mocks/MockERC20.sol";
import { IERC3156FlashLender } from "openzeppelin-contracts/contracts/interfaces/IERC3156FlashLender.sol";
import { IERC3156FlashBorrower } from "openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import { ERC20Integration } from "modulekit/integrations/ERC20.sol";
import { IPoolV3 } from "modulekit/integrations/interfaces/aaveV3/IPoolV3.sol";
import { MockedPool } from "../mocked/MockedPool.sol";
import { ERC7579BootstrapConfig } from "modulekit/external/ERC7579.sol";
import { ModuleKitFallbackHandler } from "modulekit/test/ModuleKitFallbackHandler.sol";

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
    using ModuleKitUserOp for RhinestoneAccount;
    using ModuleKitHelpers for RhinestoneAccount;
    using ModuleKitHelpers for UserOpData;

    RhinestoneAccount instance;
    FlashcallFallbackExecutor flashcallFallbackExecutor;
    MockERC20 token;
    MockedLender flashloanLender;
    IPoolV3 aavePool;
    MockValidator mockedValidator;

    function setUp() public {

        init();
        // Setup account


        token = new MockERC20();
        token.initialize("Mock Token", "MTK", 18);

        mockedValidator = new MockValidator();
        vm.label(address(mockedValidator), "mockedValidator");


        flashloanLender = new MockedLender(address(token));
        deal(address(token), address(flashloanLender), 1000000);
        vm.label(address(flashloanLender), "flashloanLender");

        aavePool = new MockedPool(address(token));
        deal(address(token), address(aavePool), 1000000);
        vm.label(address(aavePool), "aavePool");



        // Setup executor
        flashcallFallbackExecutor = new FlashcallFallbackExecutor(
            address(auxiliary.fallbackHandler),
            address(token),
            address(flashloanLender),
            address(aavePool)
        );

        vm.label(address(flashcallFallbackExecutor), "flashcallFallbackExecutor");


        ExtensibleFallbackHandler.Params[] memory params = new ExtensibleFallbackHandler.Params[](1);
        params[0] = ExtensibleFallbackHandler.Params({
            selector: IERC3156FlashBorrower.onFlashLoan.selector,
            fallbackType: ExtensibleFallbackHandler.FallBackType.Dynamic,
            handler: address(flashcallFallbackExecutor)
        });

        ERC7579BootstrapConfig[] memory validators = 
            makeBootstrapConfig(address(mockedValidator), abi.encode(""));
        ERC7579BootstrapConfig[] memory executors =
            makeBootstrapConfig(address(flashcallFallbackExecutor), abi.encode(""));
        ERC7579BootstrapConfig memory hook = _emptyConfig();
        ERC7579BootstrapConfig memory fallBack =
            _makeBootstrapConfig(address(auxiliary.fallbackHandler), abi.encode(params));

        instance = makeRhinestoneAccount("account", validators, executors, hook, fallBack);
        // instance.installFallback(
        //     IERC3156FlashBorrower.onFlashLoan.selector,
        //     false,
        //     address(flashcallFallbackExecutor)
        // );

        console2.log("account address", instance.account);
        vm.deal(instance.account, 10 ether);
        vm.label(instance.account, "account");
        vm.deal(instance.account, 100 ether);


    }

    function testExecuteAction() public {
        // Create target and ensure that it doesnt have a balance
        address target = makeAddr("target");
        assertEq(target.balance, 0);
        assertEq(token.balanceOf(instance.account), 0);

        vm.prank(instance.account);
        bytes memory origCalldata = abi.encodeWithSelector(token.transfer.selector, target, 123);
        bytes memory prependedCalldata = abi.encode(address(token), origCalldata);

        UserOpData memory userOpData = instance.getExecOps({
            target: address(flashloanLender),
            value: 0,
            callData: abi.encodeCall(
                MockedLender.flashLoan,
                    (
                        IERC3156FlashBorrower(instance.account),
                        address(token),
                        1000, 
                        prependedCalldata
                    )
                ),
            txValidator: address(defaultValidator)
        });

        userOpData.execUserOps();

        // Assert that target has a balance of 1 wei
        assertEq(token.balanceOf(target), 123);
        assertEq(token.balanceOf(instance.account), 0);
    }
}
