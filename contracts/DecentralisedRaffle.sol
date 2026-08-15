// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DecentralisedRaffle
 * @dev A raffle contract with a circuit breaker and a fair payout split
 * @notice PART 2 - Decentralised Raffle (MANDATORY)
 *
 * ---------------------------------------------------------------------------
 * IMPORTANT: THE AUTO-MARKER CALLS THESE EXACT FUNCTION AND EVENT SIGNATURES.
 * Do not rename them, reorder their parameters, or change their return types.
 * You may add anything you like alongside them.
 * ---------------------------------------------------------------------------
 */
contract DecentralisedRaffle {
    // --- Events (the marker checks these are emitted) ---
    event RaffleEntered(address indexed player, uint256 entryCount);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prize);
    event RafflePaused();
    event RaffleUnpaused();

    /// @notice The minimum a player must send for one entry
    uint256 public constant MINIMUM_ENTRY = 0.01 ether;

    /// @notice How long the raffle must run before a winner can be drawn
    uint256 public constant RAFFLE_DURATION = 24 hours;

    address public owner;
    uint256 public raffleId;
    uint256 public raffleStartTime;
    bool public isPaused;

    mapping(address => uint256) public entries;
    address[] public uniquePlayers;
    address[] public totalPlayers;

    constructor() {
        owner = msg.sender;
        raffleId = 1;
        raffleStartTime = block.timestamp;
        isPaused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    function enterRaffle() external payable {
        require(msg.value >= MINIMUM_ENTRY, "Entry amount is below minimum");
        require(!isPaused, "Raffle is paused");

        if (entries[msg.sender] == 0) {
            uniquePlayers.push(msg.sender);
        }

        entries[msg.sender]++;
        totalPlayers.push(msg.sender);

        emit RaffleEntered(msg.sender, entries[msg.sender]);
    }

    function selectWinner() external onlyOwner {
        require(block.timestamp >= raffleStartTime + RAFFLE_DURATION, "Raffle not over yet");
        require(uniquePlayers.length >= 3, "Need at least 3 unique players");

        uint256 totalEntries = totalPlayers.length;
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, raffleId))) % totalEntries;
        address winner = totalPlayers[randomIndex];

        uint256 prizeAmount = (address(this).balance * 90) / 100;
        uint256 ownerCut = address(this).balance - prizeAmount;

        payable(winner).transfer(prizeAmount);
        payable(owner).transfer(ownerCut);

        emit WinnerSelected(raffleId, winner, prizeAmount);

        raffleId++;
        for (uint256 i = 0; i < uniquePlayers.length; i++) {
            delete entries[uniquePlayers[i]];
        }
        delete uniquePlayers;
        delete totalPlayers;
        raffleStartTime = block.timestamp;
    }

    function pause() external onlyOwner {
        isPaused = true;
        emit RafflePaused();
    }

    function unpause() external onlyOwner {
        isPaused = false;
        emit RaffleUnpaused();
    }

    function getPot() external view returns (uint256) {
        return address(this).balance;
    }

    function getEntryCount(address player) external view returns (uint256) {
        return entries[player];
    }

    function getPlayerCount() external view returns (uint256) {
        return totalPlayers.length;
    }

    function getUniquePlayerCount() external view returns (uint256) {
        return uniquePlayers.length;
    }

    function refundPlayers() external onlyOwner {
        for (uint256 i = 0; i < uniquePlayers.length; i++) {
            address player = uniquePlayers[i];
            uint256 refundAmount = entries[player] * MINIMUM_ENTRY;
            if (refundAmount > 0) {
                payable(player).transfer(refundAmount);
            }
        }

        for (uint256 i = 0; i < uniquePlayers.length; i++) {
            delete entries[uniquePlayers[i]];
        }
        delete uniquePlayers;
        delete totalPlayers;
    }
}
