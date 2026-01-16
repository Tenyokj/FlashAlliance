# ⚡ FlashAlliance

**FlashAlliance** is a Solidity smart contract system that allows a group of participants to pool funds into alliances to collectively purchase NFTs.

Each alliance can vote on the sale of the purchased token and automatically distribute the proceeds according to the participants' shares.

---

## 🧩 Contracts

### **1. Alliance.sol**
> The main contract implementing the alliance logic.

**Functionality:**
- Allows multiple participants to contribute ETH to purchase NFTs.
- Checks whether the target price has been reached.
- Allows owners to vote on the sale of NFTs and initiate the sale upon reaching a quorum.
- Automatically distributes proceeds among participants according to their shares.
- Uses reentrancy protection (ReentrancyGuard by OpenZeppelin).

**Main states:**
- `Funding` — fundraising is in progress.
- `Acquired` — the NFT has been purchased and is in the alliance.
- `Closed` — the sale has been completed and funds have been distributed.

**Key functions:**
| Function | Description |
|---------|----------|
| `deposit()` | Deposits funds to the alliance fund |
| `buyNFT(address _nftAddress, uint256 _tokenId)` | Completes the NFT purchase |
| `voteToSell(uint256 price)` | Vote to sell at the specified price |
| `executeSale()` | Sells the NFT and distributes ETH among participants |

---

### **2. AllianceFactory.sol**
> A factory contract for creating and tracking alliances.

**Features:**
- Deploy new alliances with predefined participants and shares.
- Check that shares add up to 100%.
- Store a list of all created alliances.
- Emit the 'AllianceCreated' event upon successful deployment of a new contract.

**Key Functions:**
| Function | Description |
|----------|-----------|
| `createAlliance(uint256 targetPrice, uint256 deadline, address[] participants, uint256[] shares)` | Creates a new alliance |
| `getAllAlliances()` | Returns a list of all created alliances |

---

### **3. ERC721Mock.sol**
> A simplified implementation of an ERC-721 token for testing.

**Features:**
- Allows any address to mint tokens without restrictions.
- Used in tests to verify the logic of NFT buying and selling by the alliance.

**Key Functions:**
| Function | Description |
|---------|----------|
| `mint(address to, uint256 tokenId)` | Mints an NFT to the specified address |

---

## ⚙️ Technologies

- **Solidity** ^0.8.20
- **Hardhat** (as a testing and deployment framework)
- **OpenZeppelin Contracts** (ReentrancyGuard, ERC721)

---

## 🧪 Testing

Tests will be written for the following scenarios:

| Contract | Scenarios to be tested |
|-----------|----------------------|
| `Alliance` | ✅ Depositing funds<br> ✅ Checking the `targetPrice` limit<br> ✅ Buying NFTs<br>    ✅ Voting and Quorum<br> ✅ Selling and distributing funds |
| `AllianceFactory` | ✅ Creating alliances<br> ✅ Checking stake validity |
| `ERC721Mock` | ✅ Minting and transferring NFTs |

> ⚠️ Tests are in development. They will use **Mocha + Chai** and run through **Hardhat**.

---

## 🚀 How to run the project

1. Install dependencies:
```bash
npm install

Compile contracts:

npx hardhat compile

Start the local network:

npx hardhat node

Deploy a contract (example):

npx hardhat run scripts/deploy.js --network localhost

(Later) Run tests:

npx hardhat test
```
