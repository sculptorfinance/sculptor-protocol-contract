pragma solidity 0.7.6;

import "../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import "../interfaces/IMultiFeeDistribution.sol";

contract TokenVestingLinear {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable sculptorToken;
    uint256 public startTime;
    uint256 public immutable maxMintableTokens;
    uint256 public claimedTokens;
    IMultiFeeDistribution public immutable minter;
    address public immutable owner;
    address public reciever;

    struct EmissionRange {
        uint256 totalReward;
        uint256 timeRange;
    }

    EmissionRange[] public emissionRange;

    constructor(
        address _sculptorToken,
        IMultiFeeDistribution _minter,
        uint256 _maxMintable,
        address _receivers,
        uint256[] memory _time,
        uint256[] memory _amounts
    ) {
        require(_time.length == _amounts.length);
        sculptorToken = _sculptorToken;
        minter = _minter;
        uint256 mintable;
        for (uint256 i = 0; i < _time.length; i++) {
            emissionRange.push(
                EmissionRange({
                    totalReward: _amounts[i],
                    timeRange: _time[i]
                })
            );
            mintable = mintable.add(_amounts[i]);
        }
        require(mintable == _maxMintable);
        maxMintableTokens = mintable;
        reciever = _receivers;
        owner = msg.sender;
    }

    function start() external {
        require(msg.sender == owner);
        require(startTime == 0);
        startTime = block.timestamp;
    }

    function claimable() external view returns (uint256, uint256) {
        if (startTime == 0) return (0,0);
        uint256 elapsedTime = block.timestamp.sub(startTime);
        uint256 total;
        for(uint256 i = 0; i < emissionRange.length; i++){
            EmissionRange memory e = emissionRange[i];
            if(elapsedTime < e.timeRange){
                uint256 reward = e.totalReward.mul(elapsedTime).div(e.timeRange);
                total += reward;
                break;
            }else{
                total += e.totalReward;
            }
        }
        return (elapsedTime, total.sub(claimedTokens));
    }

    function claim() external {
        require(startTime > 0, "Not started yet!");
        uint256 elapsedTime = block.timestamp.sub(startTime);
        uint256 total = 0;
        for(uint256 i = 0; i < emissionRange.length; i++){
            EmissionRange memory e = emissionRange[i];
            if(elapsedTime < e.timeRange){
                uint256 reward = e.totalReward.mul(elapsedTime).div(e.timeRange);
                total += reward;
                break;
            }else{
                total += e.totalReward;
            }
        }
        uint256 amount = total.sub(claimedTokens);
        if(maxMintableTokens.sub(claimedTokens) < amount){
            amount = maxMintableTokens.sub(claimedTokens);
        }

        claimedTokens = claimedTokens + amount;
        minter.mint(address(this), amount, false);
        minter.exit();
        IERC20(sculptorToken).safeTransfer(reciever, amount);

    }
}
