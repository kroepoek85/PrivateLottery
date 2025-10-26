# Private Lottery — Fully Homomorphic, Privacy‑Preserving Raffle (Zama FHEVM)

A minimal dApp demonstrating a **sealed, privacy‑preserving lottery** on-chain:

* Each participant encrypts a small number (e.g., `uint16`) **locally**.
* The smart contract stores **only ciphertext** and never learns the picks.
* A winner is selected **without revealing** other players’ numbers.

This repo ships a one‑file frontend (`frontend/public/index.html`) and an FHEVM‑ready Solidity contract (you deploy it and paste the address into the frontend **CONFIG** block).

> **Relayer SDK**: uses `@zama-ai/relayer-sdk-js` **0.2.0** via CDN.

---

## ✨ Features

* **Private picks** — numbers encrypted in-browser; only opaque handles hit the chain.
* **On-chain confidentiality** — contract manipulates ciphertexts only.
* **Simple round flow** — `startRound` → users `join` → `draw`.
* **Non‑leaking read API** — exposes only round status and winner address.
* **Modern, compact UI** — dark theme, clear actions, no build step required.

> ⚠️ **Randomness note**: the demo draw is intentionally simple. For production, plug in verifiable randomness (e.g., Chainlink VRF or a beacon) and audit the selection logic.

---

## 🧱 Stack

* **Solidity** `^0.8.x`
* **Zama FHEVM Solidity lib** (`@fhevm/solidity`)
* **Zama Relayer SDK JS** `0.2.0`
* **ethers v6**
* **MetaMask** (EIP‑1193)
* **Network**: Sepolia testnet by default

---

## 📁 Structure

```
frontend/
  public/
    index.html   # one‑file app (UI + logic). Edit CONFIG here.
contracts/
  PrivateLottery.sol  # your FHEVM-enabled contract (example name)
```

The app is a static site — serve the `frontend/public` folder with any static server.

---

## ⚙️ Configuration

Open `frontend/public/index.html` and set the **CONFIG** at the top:

```js
const CONFIG = {
  NETWORK_NAME: "Sepolia",
  CHAIN_ID_HEX: "0xaa36a7",
  CONTRACT_ADDRESS: "0xYourDeployedContract", // ← set your address
  RELAYER_URL: "https://relayer.testnet.zama.cloud",
};
```

> Ensure the ABI block matches your deployed contract’s interface. If you extend the contract, update the ABI accordingly in `index.html`.

---

## 🚀 Quick Start

1. **Wallet & Network**

   * Install MetaMask and add **Sepolia**.

2. **Deploy the contract**

   * Compile & deploy `PrivateLottery.sol` to Sepolia (Hardhat/Foundry).
   * Copy the deployed address to `CONFIG.CONTRACT_ADDRESS`.

3. **Serve the frontend**

   ```bash
   # from repo root
   npx serve frontend/public
   # or
   python3 -m http.server --directory frontend/public 5173
   ```

   Open the printed `http://localhost:XXXX`.

4. **Use the dApp**

   * Click **Connect Wallet**.
   * **Admin** starts a round (`Round ID`).
   * **Players** join the same `Round ID`, pick a small `uint16`, and submit (encrypted).
   * **Admin** presses **Draw winner** to finalize.
   * **Read State** shows `open/closed`, `players` count, and `winner` address.

---

## 🔐 How It Works

* The frontend calls **Relayer SDK** → `createEncryptedInput(contractAddr, userAddr)` and `add16(pick)`.
* SDK returns `{ handles, inputProof }` (opaque ciphertext + attestation).
* The contract receives those values (typed as `externalEuint16` + `bytes proof`) and records them without ever seeing plaintext.
* Winner selection runs on encrypted state / metadata, avoiding pick disclosure.

---

## 🧪 Contract API (expected)

Typical public methods the UI uses:

* `function startRound(uint256 roundId) external;`
* `function join(uint256 roundId, externalEuint16 pickExt, bytes calldata proof) external;`
* `function draw(uint256 roundId) external;`
* `function playersCount(uint256 roundId) external view returns (uint256);`
* `function isOpen(uint256 roundId) external view returns (bool);`
* `function winnerOf(uint256 roundId) external view returns (address);`
* `function hasJoined(uint256 roundId, address user) external view returns (bool);`

> If your names differ, align the ABI in `index.html` accordingly.

---

## 🧭 Implementation Notes

* **Relayer SDK 0.2.0**

  * Use `createEncryptedInput(contract, user)` (positional args in 0.2.0).
  * `add16()` pushes the `uint16` value; encrypt once per `join` to bind both handle+proof.

* **No plaintext logs**

  * Ensure your contract does **not** emit or store raw picks. Only handles / round metadata should appear on-chain.

* **Randomness**

  * Replace the demo draw with **VRF** or an **audited randomness source** for real deployments.



## 🔒 Security (Production)

* Integrate **verifiable randomness** for `draw`.
* Add **access control** (only owner/admin starts/draws).
* Pin exact library versions; **audit** the contract and FHE logic.
* Consider **rate limits / deposits** to mitigate spam and griefing.



## 📜 License

MIT © Your‑Org / Your‑Name


