// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// module
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TimedRelease is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct VestingSchedule {
        address token;
        uint256[] dates;
        uint256[] amounts;
    }

    mapping(address => VestingSchedule) private beneficiaries;
    mapping(address => uint256) public releasedAmount;

    event VestCreated(address indexed to);
    event VestReleased(address indexed to, uint256 date, uint256 amount);

    function initialize() public initializer {
        __Ownable_init();
    }

    function createVestingSchedule(
        address _beneficiary,
        address _token,
        uint256[] memory _dates,
        uint256[] memory _amounts
    ) external onlyOwner {
        VestingSchedule memory schedule = beneficiaries[_beneficiary];
        require(schedule.dates.length == 0, "Already exists");

        require(_dates.length > 0, "At least one unlock date must be provided");
        require(
            _dates.length == _amounts.length,
            "Arrays must have the same length"
        );
        beneficiaries[_beneficiary] = VestingSchedule({
            token: _token,
            dates: _dates,
            amounts: _amounts
        });

        uint256 totalVestingAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalVestingAmount += _amounts[i];
        }

        IERC20Upgradeable(_token).safeTransferFrom(
            msg.sender,
            address(this),
            totalVestingAmount
        );

        emit VestCreated(_beneficiary);
    }

    function releaseTokens(address _beneficiary) external {
        VestingSchedule memory schedule = beneficiaries[_beneficiary];
        require(
            schedule.amounts.length > 0,
            "Vesting has not started yet for this beneficiary"
        );
        (, uint256 releaseableAmount, ) = getAmount(_beneficiary);

        require(releaseableAmount > 0, "No releaseable amount");
        IERC20Upgradeable(schedule.token).safeTransfer(
            _beneficiary,
            releaseableAmount
        );
        releasedAmount[_beneficiary] += releaseableAmount;
        emit VestReleased(_beneficiary, block.timestamp, releaseableAmount);
    }

    function getAmount(
        address _beneficiary
    ) public view returns (uint256, uint256, uint256) {
        VestingSchedule memory schedule = beneficiaries[_beneficiary];
        uint256 releaseableAmount;
        uint256 remainAmount;

        uint256 totalAvailable;
        uint256 totalVestingAmount;
        for (uint256 i; i < schedule.dates.length; i++) {
            if (schedule.dates[i] <= block.timestamp) {
                totalAvailable += schedule.amounts[i];
            }

            totalVestingAmount += schedule.amounts[i];
        }
        releaseableAmount = totalAvailable - releasedAmount[_beneficiary];
        remainAmount = totalVestingAmount - releasedAmount[_beneficiary];

        return (releasedAmount[_beneficiary], releaseableAmount, remainAmount);
    }

    function getVestInfo(
        address _beneficiary
    ) public view returns (address, uint256[] memory, uint256[] memory) {
        VestingSchedule memory schedule = beneficiaries[_beneficiary];
        return (schedule.token, schedule.dates, schedule.amounts);
    }
}
