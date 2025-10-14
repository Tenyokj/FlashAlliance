// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Alliance – Collective NFT Purchase and Sale
/// @notice Enables a group of participants to pool ETH to acquire an NFT,
///         vote on selling it, and automatically distribute proceeds.
/// @dev Uses OpenZeppelin ReentrancyGuard to protect against reentrancy attacks.
contract Alliance is ReentrancyGuard {

    /// @notice Address of the purchased NFT contract
    address public nftAddress;

    /// @notice ID of the purchased NFT token
    uint256 public tokenId;

    /// @notice Array of all alliance participants
    address[] public participants;

    /// @notice Lifecycle states of the alliance
    enum State { Funding, Acquired, Closed }

    /// @notice Current lifecycle state of the alliance
    State public state = State.Funding;

    /// @notice Target ETH amount required to acquire the NFT (in wei)
    uint256 public targetPrice;

    /// @notice Total amount of ETH deposited so far (in wei)
    uint256 public totalDeposited;

    /// @notice Total weight of "yes" votes for selling the NFT, expressed in percent
    uint256 public yesVotesWeight;

    /// @notice Proposed sale price, set on the first vote
    uint256 public proposedPrice;

    /// @notice Percentage of votes required to reach quorum (default: 60%)
    uint256 public quorumPercent = 60; 

    /// @notice Deadline for the funding period (Unix timestamp)
    uint256 public deadline;

    /// @notice Percentage ownership shares of each participant (0–100)
    mapping(address => uint256) public list_of_participants_and_their_shares;

    /// @notice Tracks which addresses are participants/owners
    mapping(address => bool) public isOwner;

    /// @notice Tracks whether a participant has voted to sell
    mapping(address => bool) public hasVoted;

    /// @notice Emitted when a participant deposits ETH
    /// @param user Address of the depositor
    /// @param amount Amount of ETH deposited (in wei)
    event Deposit(address indexed user, uint256 amount);

    /// @notice Initializes a new Alliance instance
    /// @param _targetPrice Target amount of ETH to raise (in wei)
    /// @param _deadline Duration of the funding period in seconds
    /// @param _participants Addresses of all participants
    /// @param _shares Percentage shares for each participant; must sum to 100
    constructor(
        uint256 _targetPrice,
        uint256 _deadline,
        address[] memory _participants,
        uint256[] memory _shares
    ) {
        require(_participants.length == _shares.length, "Participants and shares mismatch");
        targetPrice = _targetPrice;
        deadline = block.timestamp + _deadline;

        for (uint i = 0; i < _participants.length; i++) {
            participants.push(_participants[i]);
            isOwner[_participants[i]] = true;
            list_of_participants_and_their_shares[_participants[i]] = _shares[i];
        }
    }

    /// @dev Restricts a function to be callable only by an alliance participant
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only owner can call this function");
        _;
    }

    /// @dev Ensures the contract is in a specific lifecycle state
    /// @param s Expected state
    modifier inState(State s) {
        require(state == s, "Invalid state");
        _;
    }

    /// @notice Deposit ETH toward the collective purchase of the NFT
    /// @dev Can only be called while funding is active and before the deadline
    function deposit() external payable inState(State.Funding) {
        require(block.timestamp < deadline, "Funding period over");
        require(msg.value > 0, "Amount must be greater than 0");
        require(totalDeposited < targetPrice, "Target already reached");

        totalDeposited += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Finalize the NFT purchase after it has been transferred to the contract
    /// @param _nftAddress Address of the ERC721 NFT contract
    /// @param _tokenId ID of the NFT token
    /// @dev Checks that this contract is already the owner of the given token
    function buyNFT(address _nftAddress, uint256 _tokenId)
        external
        onlyOwner
        inState(State.Funding)
    {
        require(totalDeposited >= targetPrice, "Not enough funds");
        require(_nftAddress != address(0), "Invalid NFT address");
        require(IERC721(_nftAddress).ownerOf(_tokenId) == address(this), "NFT not transferred to contract");

        nftAddress = _nftAddress;
        tokenId = _tokenId;

        state = State.Acquired;
    }

    /// @notice Cast a vote to sell the NFT at a specific price
    /// @param price Proposed sale price in wei
    /// @return reached True if the quorum has been met after this vote
    function voteToSell(uint256 price)
        external
        inState(State.Acquired)
        returns (bool reached)
    {
        require(isOwner[msg.sender], "Not a participant");
        require(!hasVoted[msg.sender], "Already voted");

        if (proposedPrice == 0) {
            proposedPrice = price;
        } else {
            require(price == proposedPrice, "Price mismatch");
        }

        hasVoted[msg.sender] = true;
        yesVotesWeight += list_of_participants_and_their_shares[msg.sender];

        return yesVotesWeight >= quorumPercent;
    }

    /// @notice Execute the sale and distribute the proceeds proportionally to participant shares
    /// @dev Assumes the buyer has already sent ETH to this contract
    function executeSale()
        external
        onlyOwner
        inState(State.Acquired)
        nonReentrant
    {
        require(yesVotesWeight >= quorumPercent, "Quorum not reached");
        require(IERC721(nftAddress).ownerOf(tokenId) == address(this), "NFT not owned by contract");

        uint256 totalFunds = address(this).balance;

        for (uint i = 0; i < participants.length; i++) {
            address p = participants[i];
            uint256 sharePercent = list_of_participants_and_their_shares[p];
            uint256 payout = (totalFunds * sharePercent) / 100;

            if (payout > 0) {
                (bool ok, ) = payable(p).call{value: payout}("");
                require(ok, "Transfer failed");
            }
        }

        state = State.Closed;
    }

    receive() external payable {}
}
