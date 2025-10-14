// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./Alliance.sol";

/// @title AllianceFactory – Deployer for Alliance Contracts
/// @notice Deploys and tracks multiple Alliance instances where participants can pool ETH to purchase NFTs.
/// @dev Maintains an on-chain registry of all created Alliance contracts.
contract AllianceFactory {

    /// @notice Array storing all deployed Alliance contract instances
    Alliance[] public alliances;

    /// @notice Emitted when a new Alliance contract is successfully created
    /// @param allianceAddress The address of the newly deployed Alliance contract
    event AllianceCreated(address allianceAddress);

    /// @notice Deploy a new Alliance contract
    /// @dev Verifies that the sum of all participant shares equals exactly 100
    /// @param _targetPrice Total ETH target required to fund the NFT purchase (in wei)
    /// @param _deadline Funding duration in seconds from the time of creation
    /// @param _participants Array of participant addresses who will own the alliance
    /// @param _shares Percentage share (0–100) for each participant; must sum to 100
    /// @return The address of the newly created Alliance contract
    function createAlliance(
        uint256 _targetPrice,
        uint256 _deadline,
        address[] memory _participants,
        uint256[] memory _shares
    ) external returns (address) {
        require(_participants.length == _shares.length, "Participants/shares mismatch");

        // Ensure that the total of all shares equals exactly 100%
        uint256 sumShares = 0;
        for (uint i = 0; i < _shares.length; i++) {
            sumShares += _shares[i];
        }
        require(sumShares == 100, "Shares must sum to 100%");

        Alliance alliance = new Alliance(_targetPrice, _deadline, _participants, _shares);
        alliances.push(alliance);

        emit AllianceCreated(address(alliance));
        return address(alliance);
    }

    /// @notice Retrieve the list of all deployed Alliance contracts
    /// @return An array containing every Alliance instance created by this factory
    function getAllAlliances() external view returns (Alliance[] memory) {
        return alliances;
    }
}