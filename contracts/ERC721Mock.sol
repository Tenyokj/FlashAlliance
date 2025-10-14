// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title ERC721Mock
/// @notice Simple mock implementation of an ERC-721 token for testing purposes.
/// @dev Extends OpenZeppelin’s ERC721 and exposes a public mint function
///      to allow anyone to mint tokens without access control.
contract ERC721Mock is ERC721 {
    /// @notice Counter that can be used to track minted token IDs if desired.
    /// @dev This variable is not automatically incremented; it is left for testing flexibility.
    uint256 public tokenIdCounter;

    /// @notice Deploys the mock ERC721 contract.
    /// @param name Token collection name.
    /// @param symbol Token symbol.
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /// @notice Mints a new token with a specified `tokenId` to the given address.
    /// @dev No access control or supply limits are enforced; intended only for testing.
    /// @param to The address that will receive the minted token.
    /// @param tokenId The unique identifier for the token to mint.
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
