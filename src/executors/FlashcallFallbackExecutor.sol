// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IFallbackMethod } from "modulekit/core/ExtensibleFallbackHandler.sol";
import { ERC20Integration } from "modulekit/integrations/ERC20.sol";
import { IERC3156FlashBorrower } from "openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IPoolV3 } from "modulekit/integrations/interfaces/aaveV3/IPoolV3.sol";
import { ERC7579ExecutorBase } from "modulekit/Modules.sol";
// import { IERC7579Execution } from "modulekit/Accounts.sol";
import { IERC7579Execution } from "modulekit/external/ERC7579.sol";

contract FlashcallFallbackExecutor is IFallbackMethod, ERC7579ExecutorBase {

    bytes32 private constant CALLBACK_SUCCESS = keccak256('ERC3156FlashBorrower.onFlashLoan');

    address private fallbackHandler;
    address private authorizedLender;
    address private aavePool;
    IERC20 private token;

    constructor (
        address _fallbackHandler,
        address _token,
        address _authorizedLender,
        address _aavePool
    ) {
        fallbackHandler = _fallbackHandler;
        token = IERC20(_token);
        authorizedLender = _authorizedLender;
        aavePool = _aavePool;
    }

    function onInstall(bytes calldata data) external {}
    function onUninstall(bytes calldata data) external {}

    function handle(
        address account,
        address sender,
        uint256 value,
        bytes calldata data
    )
        external
        returns (bytes memory result){
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
    ) internal view returns (IERC7579Execution.Execution memory exec) {
        exec = IERC7579Execution.Execution({
            target: payable(address(aavePool)),
            value: 0,
            callData: abi.encodeWithSelector(IPoolV3.borrow.selector, address(token), toBorrowTokenAmount, 1, 0, account)
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
        (address to, bytes memory callData) =
            abi.decode(data, (address, bytes));
        
        IERC7579Execution.Execution[] memory exec = new IERC7579Execution.Execution[](1);
        exec[0] = IERC7579Execution.Execution({
            target: to,
            value: 0,
            callData: callData
        });
        _execute(account, exec);

        uint256 haveTokenAmount = token.balanceOf(account);
        uint256 toBorrowTokenAmount = amount + fee - haveTokenAmount;
        if (toBorrowTokenAmount > 0) {
            IERC7579Execution.Execution[] memory aaveBorrow  = new IERC7579Execution.Execution[](1);
            aaveBorrow[0] = aaveBorrowAction(toBorrowTokenAmount, account);
            _execute(account, aaveBorrow);
        }

        IERC7579Execution.Execution[] memory approveDebt  = new IERC7579Execution.Execution[](1);
        approveDebt[0] = ERC20Integration.approve(
            token,
            authorizedLender,
            amount+fee
        );
        _execute(account, approveDebt);

    }

    /**
     * @notice A funtion that returns name of the executor
     * @return name string name of the executor
     */
    function name() external pure override returns (string memory name) {
        name = "ExecutorTemplate";
    }

    /**
     * @notice A funtion that returns version of the executor
     * @return version string version of the executor
     */
    function version() external pure override returns (string memory version) {
        version = "0.0.1";
    }

    function isModuleType(uint256 typeID) external view returns (bool) {
        return typeID == 2;
    }

}
