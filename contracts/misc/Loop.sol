// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../dependencies/openzeppelin/contracts/IERC20.sol";
import "../interfaces/ILendingPool.sol";

contract Loop {
    using SafeMath for uint256;

    uint256 public constant BORROW_RATIO_DECIMALS = 4;

    /// @notice Lending Pool address
    ILendingPool public lendingPool;

    constructor(ILendingPool _lendingPool) {
        lendingPool = _lendingPool;
    }

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory) {
        return lendingPool.getConfiguration(asset);
    }

    /**
     * @dev Returns variable debt token address of asset
     * @param asset The address of the underlying asset of the reserve
     * @return varaiableDebtToken address of the asset
     **/
    function getVDebtToken(address asset) public view returns (address) {
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(asset);
        return reserveData.variableDebtTokenAddress;
    }

    /**
     * @dev Returns loan to value
     * @param asset The address of the underlying asset of the reserve
     * @return ltv of the asset
     **/
    function ltv(address asset) public view returns (uint256) {
        DataTypes.ReserveConfigurationMap memory conf =  lendingPool.getConfiguration(asset);
        return conf.data % (2 ** 16);
    }

    /**
     * @dev Calcualte asset after Loop the deposit and borrow
     * @param amount for the initial deposit
     * @param borrowRatio Ratio of tokens to borrow
     * @param loopCount Repeat count for loop
     * @return value of collateral and borrow
     **/
    function getCollateralBorrow(
        uint256 amount,
        uint256 borrowRatio,
        uint256 loopCount
    ) public pure returns (uint256, uint256) {
        uint256 amountIn = amount;
        uint256 borrow = 0;
        for (uint256 i = 0; i < loopCount; i += 1) {
            amount = amount.mul(borrowRatio).div(10 ** BORROW_RATIO_DECIMALS);
            borrow = borrow + amount;
        }
        uint256 totalCol = borrow + amountIn;
        return (totalCol, borrow);
    }

    /**
     * @dev Loop the deposit and borrow of an asset
     * @param asset for loop
     * @param amount for the initial deposit
     * @param interestRateMode stable or variable borrow mode
     * @param borrowRatio Ratio of tokens to borrow
     * @param loopCount Repeat count for loop
     **/
    function loop(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint256 borrowRatio,
        uint256 loopCount
    ) external {
        uint16 referralCode = 0;
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(lendingPool), type(uint256).max);
        lendingPool.deposit(asset, amount, msg.sender, referralCode);
        for (uint256 i = 0; i < loopCount; i += 1) {
            amount = amount.mul(borrowRatio).div(10 ** BORROW_RATIO_DECIMALS);
            lendingPool.borrow(asset, amount, interestRateMode, referralCode, msg.sender);
            lendingPool.deposit(asset, amount, msg.sender, referralCode);
        }
    }
}