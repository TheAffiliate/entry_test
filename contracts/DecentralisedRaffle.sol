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

    // TODO: Define the rest of your state variables here.
    // Consider:
    // - One call to enterRaffle() buys ONE entry, and a player may enter many
    //   times. An array of addresses records every entry in order - the same
    //   address simply appears more than once, which gives them better odds.
    // - You also need the number of UNIQUE players, for the 3-player minimum.
    // - The pot is just this contract's balance.

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

    // -----------------------------------------------------------------------
    // TODO 1: enterRaffle
    // -----------------------------------------------------------------------
    // Requirements:
    // - Revert if msg.value is below MINIMUM_ENTRY
    // - Revert while the raffle is paused
    // - Record ONE entry for msg.sender (they may enter repeatedly)
    // - If this is the caller's first ever entry this round, they are a new
    //   unique player
    // - Emit RaffleEntered(msg.sender, <this player's total entries so far>)
    function enterRaffle() external payable {
        // Your implementation here
        if (msg.value < MINIMUM_ENTRY) {
            revert("Entry amount is below minimum");
        }
        if (isPaused) {
            revert("Raffle is paused");
        }
        if (entries[msg.sender] == 0){
            uniquePlayers.push(msg.sender);
        }
        entries[msg.sender]++;
        emit RaffleEntered(msg.sender, entries[msg.sender]);
    }

    // -----------------------------------------------------------------------
    // TODO 2: selectWinner
    // -----------------------------------------------------------------------
    // Requirements:
    // - Only the owner may call it
    // - Revert unless at least RAFFLE_DURATION has passed since raffleStartTime
    // - Revert unless there are at least 3 UNIQUE players
    // - Pick a winning index across ALL entries, so a player with 3 entries is
    //   three times as likely to win as a player with 1
    // - Pay 90% of the pot to the winner and 10% to the owner
    // - Emit WinnerSelected(raffleId, winner, prizeAmount)
    // - Reset for the next round: increment raffleId, clear the entries, and
    //   set raffleStartTime to now
    //
    // MATHS: calculate the prize as (pot * 90) / 100. Multiply before you
    // divide, or you will lose precision.
    //
    // RANDOMNESS - read this carefully, it is the point of the exercise:
    // You will probably reach for something like
    //     uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)))
    // That is ACCEPTABLE for this assessment, because a genuinely secure
    // source (Chainlink VRF, commit-reveal) is beyond a 3-hour test. What is
    // NOT acceptable is pretending it is secure. In PartB_Design.md you must
    // explain who can manipulate your randomness, how, and what you would use
    // in production instead. That explanation carries the marks here, not the
    // code.
    function selectWinner() external onlyOwner {
        // Your implementation here
        selectWinner storage winner = uniquePlayers[uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % uniquePlayers.length];
        uint256 prizeAmount = (address(this).balance * 90) / 100;
        payable(winner).transfer(prizeAmount);
        payable(owner).transfer(address(this).balance);
        emit WinnerSelected(raffleId, winner, prizeAmount);
        raffleId++;
        delete uniquePlayers;
        raffleStartTime = block.timestamp;
    }
    }

    // -----------------------------------------------------------------------
    // TODO 3: Circuit breaker
    // -----------------------------------------------------------------------
    // Requirements:
    // - Owner only, both functions
    // - Set isPaused, and emit RafflePaused() / RaffleUnpaused()
    function pause() external onlyOwner {
        // Your implementation
        pause storage isPaused = true;
    }

    function unpause() external onlyOwner {
        // Your implementation
        unpause storage isPaused = false;
    }

    // -----------------------------------------------------------------------
    // TODO 4: View functions (the marker calls all four)
    // -----------------------------------------------------------------------

    /// @notice The current pot, in wei
    function getPot() external view returns (uint256) {
        // Your implementation here
        getPot storage pot = address(this).balance;
    }

    /// @notice How many entries this player has bought this round
    function getEntryCount(address player) external view returns (uint256) {
        // Your implementation here
        getEntryCount storage entries = entries[player];
    }

    /// @notice Total number of entries this round, counting repeats
    function getPlayerCount() external view returns (uint256) {
        // Your implementation here
        getPlayerCount storage playerCount = totalPlayers.length;
    }

    /// @notice Number of distinct addresses that have entered this round
    function getUniquePlayerCount() external view returns (uint256) {
        // Your implementation here
        getUniquePlayerCount storage uniquePlayerCount = uniquePlayers.length;
    }

    // BONUS (not auto-marked, describe it in PartB_Design.md instead):
    // - Refund everyone if the raffle closes with fewer than 3 players
    // - Multiple prize tiers (1st, 2nd, 3rd)

    function refundPlayers() external onlyOwner{
        refundPlayers storage uniquePlayers = uniquePlayers;
        for (uint256 i = 0; i < uniquePlayers.length; i++){
            address player = uniquePlayers[i];
            uint256 playerEntries = entries[player];
            uint256 refundAmount = playerEntries * MINIMUM_ENTRY;
            payable(player).transfer(refundAmount);
        })
    }
}
