# FlashAlliance Contract Documentation

## Overview

FlashAlliance is a standalone ERC20-funded collective NFT trading module.
Each `Alliance` instance is a self-contained pool with fixed participants and fixed ownership shares.

This module is intentionally separate from BERT core governance contracts.
In BERT terms, FlashAlliance should be treated as an ecosystem add-on product, not a core DAO primitive.
Administrative controls are local (`Ownable`) per alliance.

## Architecture

### 1. `AllianceFactory`

File: `src/FlashAlliance/AllianceFactory.sol`

Purpose:
- Deploys new `Alliance` contracts
- Maintains on-chain list of deployed alliances

Key behavior:
- `createAlliance(...)` validates shares and token address
- caller of `createAlliance(...)` becomes `owner` of the created `Alliance`

### 2. `Alliance`

File: `src/FlashAlliance/Alliance.sol`

Purpose:
- Collect deposits in ERC20
- Buy NFT from direct seller
- Run governance-lite voting for sale
- Execute sale and distribute proceeds

States:
- `Funding`
- `Acquired`
- `Closed`

Core storage:
- `targetPrice`, `deadline`, `totalDeposited`
- `participants[]`, `sharePercent[address]`, `contributed[address]`
- proposal fields: `proposedBuyer`, `proposedPrice`, `proposedSaleDeadline`
- quorum: `quorumPercent` and `lossSaleQuorumPercent`

Main functions:
- `deposit(uint256 amount)`
- `cancelFunding()`
- `buyNFT(address nft, uint256 tokenId, address seller)`
- `voteToSell(address buyer, uint256 price, uint256 saleDeadline)`
- `resetSaleProposal()`
- `executeSale()`
- `voteEmergencyWithdraw(address recipient)`
- `emergencyWithdrawNFT()`
- `withdrawRefund()`
- `pause()` / `unpause()` (only alliance owner)

Sale policy:
- Normal sale (`price >= minSalePrice`) requires `quorumPercent` (default 60)
- Loss sale (`price < minSalePrice`) requires `lossSaleQuorumPercent` (default 80)

Refund policy:
- funding must fail (deadline passed and target not reached)
- participant triggers `cancelFunding()`
- participants claim own deposit via `withdrawRefund()`

Emergency path:
- participants vote recipient through `voteEmergencyWithdraw(...)`
- on quorum, NFT can be rescued via `emergencyWithdrawNFT()`

### 3. `TenyokjToken`

File: `src/FlashAlliance/TenyokjToken.sol`

Purpose:
- ERC20 token for funding and settlements

Capabilities:
- owner mint
- owner pause/unpause
- burn and permit support

### 4. `ERC721Mock`

File: `src/FlashAlliance/ERC721Mock.sol`

Purpose:
- Test-only NFT contract for local/testnet scenarios

## Access Control Model

- Alliance admin: `Ownable` owner set at deployment (`_admin`)
- Alliance participants: fixed allowlist via `isParticipant`
- Business actions are participant-gated (`onlyParticipant`)
- Pause controls are owner-gated (`onlyOwner`)

## Events

`Alliance` emits:
- `Deposit`
- `FundingCancelled`
- `Refunded`
- `NFTBought`
- `Voted`
- `SaleProposalReset`
- `SaleExecuted`
- `EmergencyVoted`
- `EmergencyWithdrawn`

`AllianceFactory` emits:
- `AllianceCreated`

## Security Notes

- Reentrancy-protected external state-changing paths use `ReentrancyGuard`
- ERC20 interactions use `SafeERC20`
- NFT transfers use `safeTransferFrom`
- Share sum is enforced at construction (`== 100`)
- Last-recipient payout in `_distribute` absorbs rounding dust

## Operational Notes

- Seller must approve NFT to Alliance before `buyNFT`
- Buyer must approve ERC20 to Alliance before `executeSale`
- If you need stronger admin security, set alliance owner to a multisig

## Test Coverage

Foundry tests are located at:
- `test/flash/FlashAlliance.t.sol`

Coverage targets for `src/FlashAlliance/*` are above 90% and currently at 100% line/function in Foundry report.
