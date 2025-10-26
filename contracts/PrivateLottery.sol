// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * PrivateLottery
 * - Игроки отправляют зашифрованные числа (uint16) при входе в раунд.
 * - Контракт хранит только ciphertext (euint16); индивидуальные ставки не раскрываются.
 * - Победитель выбирается случайно среди участников; сами числа не используются
 *   (их цель — продемонстрировать приватный ввод).
 * - Для демонстрации случайности используется seed на базе block.prevrandao/ts/roundId.
 *   Для продакшена подключите VRF/relay-рандом.
 */

import { FHE, euint16, externalEuint16 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract PrivateLottery is SepoliaConfig {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }

    event RoundStarted(uint256 indexed roundId);
    event Joined(uint256 indexed roundId, address indexed player);
    event Drawn(uint256 indexed roundId, address indexed winner, uint256 players);

    struct Round {
        bool open;
        bool drawn;
        address winner;
        address[] players;
        mapping(address => bool) joined;
        mapping(address => euint16) pick; // encrypted choice per player
    }

    mapping(uint256 => Round) private _round;

    /* ------------------------- Admin ------------------------- */

    function startRound(uint256 roundId) external onlyOwner {
        Round storage r = _round[roundId];
        require(!r.open && !r.drawn, "round busy");
        // перезапуск: создаём новый storage-слот
        Round storage n = _round[roundId];
        n.open = true;
        n.drawn = false;
        n.winner = address(0);
        emit RoundStarted(roundId);
    }

    function draw(uint256 roundId) external onlyOwner {
        Round storage r = _round[roundId];
        require(r.open, "not open");
        uint256 n = r.players.length;
        require(n > 0, "no players");

        // псевдо-рандом для демо
        uint256 seed = uint256(
            keccak256(
                abi.encode(block.prevrandao, block.timestamp, roundId, n, address(this))
            )
        );
        address winner = r.players[seed % n];
        r.winner = winner;
        r.drawn = true;
        r.open = false;

        emit Drawn(roundId, winner, n);
    }

    /* ------------------------- Player ------------------------ */

    /// @notice Вход в раунд с зашифрованным числом (uint16)
    /// @param roundId Идентификатор раунда
    /// @param pickExt externalEuint16 из Relayer SDK (тот же encrypt() для всех входов не обязателен)
    /// @param attestation Доказательство корректности encrypt()
    function join(
        uint256 roundId,
        externalEuint16 pickExt,
        bytes calldata attestation
    ) external {
        Round storage r = _round[roundId];
        require(r.open, "round closed");
        require(!r.joined[msg.sender], "already joined");

        // валидация/десериализация ciphertext
        euint16 pick = FHE.fromExternal(pickExt, attestation);

        // сохраним зашифрованный выбор игрока
        r.pick[msg.sender] = pick;
        r.joined[msg.sender] = true;
        r.players.push(msg.sender);

        // контракту может понадобиться доступ к ciphertext (чтобы не терять ACL)
        FHE.allowThis(r.pick[msg.sender]);

        emit Joined(roundId, msg.sender);
    }

    /* -------------------------- Views ------------------------ */

    function isOpen(uint256 roundId) external view returns (bool) {
        return _round[roundId].open;
    }

    function playersCount(uint256 roundId) external view returns (uint256) {
        return _round[roundId].players.length;
    }

    function winnerOf(uint256 roundId) external view returns (address) {
        require(_round[roundId].drawn, "not drawn");
        return _round[roundId].winner;
    }

    function hasJoined(uint256 roundId, address user) external view returns (bool) {
        return _round[roundId].joined[user];
    }
}
