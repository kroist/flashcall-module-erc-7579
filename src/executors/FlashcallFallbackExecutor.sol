// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ExecutorBase } from "modulekit/modulekit/ExecutorBase.sol";
import { IExecutorManager, ExecutorAction, ModuleExecLib } from "modulekit/modulekit/IExecutor.sol";
import { IFallbackMethod } from "modulekit/common/FallbackHandler.sol";
import { ERC20ModuleKit } from "modulekit/modulekit/integrations/ERC20Actions.sol";
import { IERC3156FlashBorrower } from "openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IPoolV3 } from "modulekit/modulekit/integrations/interfaces/aaveV3/IPoolV3.sol";

contract FlashcallFallbackExecutor is ExecutorBase, IFallbackMethod {
    using ModuleExecLib for IExecutorManager;

    bytes32 private constant CALLBACK_SUCCESS = keccak256('ERC3156FlashBorrower.onFlashLoan');

    address private fallbackHandler;
    address private authorizedLender;
    IERC20 private token;

    constructor (
        address _fallbackHandler,
        address _token,
        address _authorizedLender
    ) {
        fallbackHandler = _fallbackHandler;
        token = IERC20(_token);
        authorizedLender = _authorizedLender;
    }

    function handle(
        address account,
        address sender,
        uint256 value,
        bytes calldata data
    )
        external
        returns (bytes memory result) {
        if (data.length < 4) revert();
        if (msg.sender != fallbackHandler) revert();

        bytes4 selector = bytes4(data[0:4]);

        if (selector == IERC3156FlashBorrower.onFlashLoan.selector) {
            (
                address initiator,
                address token,
                uint256 amount,
                uint256 fee,
                bytes memory data
            ) = abi.decode(data[4:], (address, address, uint256, uint256, bytes));
            _onFlashloan(account, sender, initiator, token, amount, fee, data);
            return abi.encode(CALLBACK_SUCCESS);
        }
        
    }

    function aaveBorrowAction(
        uint256 toBorrowTokenAmount,
        address account
    ) internal view returns (ExecutorAction memory action) {
        action = ExecutorAction({
            to: payable(address(token)),
            value: 0,
            data: abi.encodeWithSelector(IPoolV3.borrow.selector, address(token), toBorrowTokenAmount, 1, 0, account)
        });
    }

    function _onFlashloan(
        address account,
        address sender,
        address initiator,
        address _token,
        uint256 amount,
        uint256 fee,
        bytes memory data
    ) internal {
        if (sender != authorizedLender) revert();
        if (initiator != account) revert();
        if (_token != address(token)) revert();
        (IExecutorManager manager, address to, bytes memory callData) =
            abi.decode(data, (IExecutorManager, address, bytes));
        // manager.exec(account, to, callData);

        uint256 haveTokenAmount = token.balanceOf(account);
        uint256 toBorrowTokenAmount = amount + fee - haveTokenAmount;
        if (toBorrowTokenAmount > 0) {
            ExecutorAction memory aaveBorrow = aaveBorrowAction(toBorrowTokenAmount, account);
            manager.exec(account, aaveBorrow);
        }

        ExecutorAction memory approveDebt = ERC20ModuleKit.approveAction(
            token,
            authorizedLender,
            amount+fee
        );
        manager.exec(account, approveDebt);

    }

    /**
     * @notice A funtion that returns name of the executor
     * @return name string name of the executor
     */
    function name() external view override returns (string memory name) {
        name = "ExecutorTemplate";
    }

    /**
     * @notice A funtion that returns version of the executor
     * @return version string version of the executor
     */
    function version() external view override returns (string memory version) {
        version = "0.0.1";
    }

    /**
     * @notice A funtion that returns version of the executor.
     * @return providerType uint256 Type of metadata provider
     * @return location bytes
     */
    function metadataProvider()
        external
        view
        override
        returns (uint256 providerType, bytes memory location)
    {
        providerType = 0;
        location = "";
    }

    /**
     * @notice A function that indicates if the executor requires root access to a Safe.
     * @return requiresRootAccess True if root access is required, false otherwise.
     */
    function requiresRootAccess() external view override returns (bool requiresRootAccess) {
        requiresRootAccess = false;
    }
}
