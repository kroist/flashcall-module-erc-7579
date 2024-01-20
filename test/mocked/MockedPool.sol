// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IPoolV3 } from "modulekit/modulekit/integrations/interfaces/aaveV3/IPoolV3.sol";
import { DataTypes } from "modulekit/modulekit/integrations/interfaces/aaveV3/DataTypes.sol";
import { IPoolAddressesProvider } from "modulekit/modulekit/integrations/interfaces/aaveV3/IPoolAddressesProvider.sol";
import { MockERC20 } from "forge-std/mocks/MockERC20.sol";

contract MockedPool is IPoolV3 {
    MockERC20 token;

    constructor(address _token) {
        token = MockERC20(_token);
    }
    
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    )
        external override {
        
        token.transfer(msg.sender, amount);
    }
    
    function mintUnbacked(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    )
        external {}

    function backUnbacked(address asset, uint256 amount, uint256 fee) external {}

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    )
        external {}

    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    )
        external {}

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {return 0;}

    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    )
        external
        returns (uint256) {return 0;}

    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    )
        external
        returns (uint256) {return 0;}

    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    )
        external
        returns (uint256) {return 0;}

    function swapBorrowRateMode(address asset, uint256 interestRateMode) external {}

    function rebalanceStableBorrowRate(address asset, address user) external {}

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external {}

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    )
        external {}

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    )
        external {}

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    )
        external {}

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) {return (0,0,0,0,0,0);}

    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    )
        external {}

    function dropReserve(address asset) external {}

    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    )
        external {}

    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    )
        external {}

    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory) {
            return DataTypes.ReserveConfigurationMap(0);
        }

    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory) {
            return DataTypes.UserConfigurationMap(0);
        }

    function getReserveNormalizedIncome(address asset) external view returns (uint256) {return 0;}

    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256) {return 0;}

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory) {
        return DataTypes.ReserveData(
            DataTypes.ReserveConfigurationMap(0),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            address(0),
            address(0),
            address(0),
            address(0),
            0,
            0,
            0
        );
    }

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    )
        external {}

    function getReservesList() external view returns (address[] memory) {
        address[] memory arr;
        return arr;
    }

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider) {return IPoolAddressesProvider(address(0));}

    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external {}

    function updateFlashloanPremiums(
        uint128 flashLoanPremiumTotal,
        uint128 flashLoanPremiumToProtocol
    )
        external {}

    function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external {}

    function getEModeCategoryData(uint8 id)
        external
        view
        returns (DataTypes.EModeCategory memory) {return DataTypes.EModeCategory(0,0,0,address(0),"");}

    function setUserEMode(uint8 categoryId) external {}

    function getUserEMode(address user) external view returns (uint256) {return 0;}

    function resetIsolationModeTotalDebt(address asset) external {}

    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256) {return 0;}

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128) {return 0;}

    function BRIDGE_PROTOCOL_FEE() external view returns (uint256) {return 0;}

    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128) {return 0;}

    function MAX_NUMBER_RESERVES() external view returns (uint16) {return 0;}

    function mintToTreasury(address[] calldata assets) external {}

    function rescueTokens(address token, address to, uint256 amount) external {}

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    )
        external {}

    function getReserveAddressById(uint16 id) external view returns (address) {return address(0);}
}