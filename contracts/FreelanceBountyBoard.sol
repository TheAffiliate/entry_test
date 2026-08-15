// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title FreelanceBountyBoard
 * @dev A decentralised marketplace for skills and bounties
 * @notice PART 1 - Freelance Bounty Board (MANDATORY)
 *
 * ---------------------------------------------------------------------------
 * IMPORTANT: THE AUTO-MARKER CALLS THESE EXACT FUNCTION AND EVENT SIGNATURES.
 * Do not rename them, reorder their parameters, or change their return types.
 * You may add anything you like alongside them.
 * ---------------------------------------------------------------------------
 */
contract FreelanceBountyBoard {
    /// @notice Open = posted, Submitted = work handed in, Completed = paid
    enum Status {
        Open,
        Submitted,
        Completed
    }

    // --- Events (the marker checks these are emitted) ---

    event FreelancerRegistered(address indexed freelancer, string skill);
    event BountyPosted(uint256 indexed bountyId, address indexed employer, uint256 amount);
    event AppliedForBounty(uint256 indexed bountyId, address indexed freelancer);
    event WorkSubmitted(uint256 indexed bountyId, address indexed freelancer, string submissionUrl);
    event BountyPaid(uint256 indexed bountyId, address indexed freelancer, uint256 amount);

    address public owner;

    /// @notice Total number of bounties ever posted. The first bounty has id 1.
    uint256 public bountyCount;

    // TODO: Define the rest of your state variables here.
    // Consider:
    // - How do you record who is registered, and with which skill?
    // - What does a bounty need to remember? (employer, description, skill,
    //   amount, status) A struct is a good fit here.
    // - How do you remember who applied for which bounty?

    constructor() {
        owner = msg.sender;
    }

    // -----------------------------------------------------------------------
    // TODO 1: registerFreelancer
    // -----------------------------------------------------------------------
    // Requirements:
    // - Store the caller's skill
    // - Revert if the caller is already registered
    // - Revert if the skill string is empty
    // - Emit FreelancerRegistered(msg.sender, skill)
    function registerFreelancer(string calldata skill) external {
        // Your implementation here
         FreeLancer storage freeLancer = freeLancers[msg.sender];
        if (bytes(skill).legnth == 0) {
            revert("Skill cannot be empty");
        }
        if (bytes(freeLancer.skill).length != 0) {
            revert("Freelancer already registered");
        }
        freeLancer.skill = skill;
        emit FreelancerRegistered(msg.sender, skill);
    }

    // -----------------------------------------------------------------------
    // TODO 2: postBounty
    // -----------------------------------------------------------------------
    // Requirements:
    // - The employer sends the reward as msg.value; revert if it is zero
    // - Increment bountyCount; the new bounty's id is the new bountyCount
    // - Store employer, description, skillRequired, amount, Status.Open
    // - Emit BountyPosted(bountyId, msg.sender, msg.value)
    // - Return the new bountyId
    //
    // Think: the ETH simply stays in this contract until approval. You do not
    // need to send it anywhere yet.
    function postBounty(string calldata description, string calldata skillRequired)
        external
        payable
        returns (uint256)
    {
        // Your implementation here
        if (msg.value == 0) {
            revert("Bounty amount must be greater than zero");
        }
        bountyCount++;
        bounties[bountyCount] = Bounty({
            employer: msg.sender,
            description: description,
            skillRequired: skillRequired,
            amount: msg.value,
            status: Status.Open
        });
        emit BountyPosted(bountyCount, msg.sender, msg.value);
        return bountyCount;
    }

    // -----------------------------------------------------------------------
    // TODO 3: applyForBounty
    // -----------------------------------------------------------------------
    // Requirements:
    // - Caller must be a registered freelancer
    // - The bounty must exist and still be Open
    // - The caller's skill must match the bounty's skillRequired
    // - Revert on a duplicate application
    // - Emit AppliedForBounty(bountyId, msg.sender)
    //
    // Hint: Solidity cannot compare strings with ==. Compare hashes instead:
    //   keccak256(bytes(a)) == keccak256(bytes(b))
    function applyForBounty(uint256 bountyId) external {
        // Your implementation here
        require(bytes(freelancers[msg.sender].skill).length != 0, "Caller is not a registered freelancer");
        bouunty storage bounty = bounties[bountyId];
        require(bounty.status == Status.Open, "Bounty is not open");
        require(keccak256(bytes(freelancers[msg.sender].skill)) == keccak256(bytes(bounty.skillRequired)), "Freelancer skill does not match bounty requirement");
        require(!hasApplied[bountyId][msg.sender], "Freelancer has already applied for this bounty");
        hasApplied[bountyId][msg.sender] = true;
        emit AppliedForBounty(bountyId, msg.sender);
    }

    // -----------------------------------------------------------------------
    // TODO 4: submitWork
    // -----------------------------------------------------------------------
    // Requirements:
    // - Caller must have applied for this bounty
    // - The bounty must still be Open
    // - Set the bounty's status to Submitted
    // - Emit WorkSubmitted(bountyId, msg.sender, submissionUrl)
    function submitWork(uint256 bountyId, string calldata submissionUrl) external {
        // Your implementation here
        submit storage bounty = bounties[bountyId];
        require(hasApplied[bountyId][msg.sender],"Caller has not applied for this bounty");
        require(bounty.status == Status.Open, "Bounty is not open");
        bounty.status = Status.Submitted;
        emit WorkSubmitted(bountyId, msg.sender, submissionUrl);
    }

    // -----------------------------------------------------------------------
    // TODO 5: approveAndPay
    // -----------------------------------------------------------------------
    // Requirements:
    // - Only the employer who posted this bounty may call it
    // - The bounty must be in Submitted status (so it cannot be paid twice)
    // - Pay the full bounty amount to the freelancer
    // - Emit BountyPaid(bountyId, freelancer, amount)
    //
    // SECURITY - this is the marked part:
    // Use checks-effects-interactions. Set the status to Completed BEFORE
    // sending the ETH, so a malicious freelancer contract cannot call back in
    // and be paid twice. Send with:
    //     (bool ok, ) = freelancer.call{value: amount}("");
    //     require(ok, "Transfer failed");
    // rather than transfer() or send().
    function approveAndPay(uint256 bountyId, address freelancer) external {
        // Your implementation here
    }

    // -----------------------------------------------------------------------
    // TODO 6: View functions (the marker calls all four)
    // -----------------------------------------------------------------------

    /// @notice True if this address has registered as a freelancer
    function isRegistered(address freelancer) external view returns (bool) {
        // Your implementation here
    }

    /// @notice The skill this freelancer registered with ("" if unregistered)
    function getSkill(address freelancer) external view returns (string memory) {
        // Your implementation here
    }

    /// @notice True if this freelancer applied for this bounty
    function hasApplied(uint256 bountyId, address freelancer) external view returns (bool) {
        // Your implementation here
    }

    /// @notice All of a bounty's details, in this exact order
    function getBounty(uint256 bountyId)
        external
        view
        returns (
            address employer,
            string memory description,
            string memory skillRequired,
            uint256 amount,
            Status status
        )
    {
        // Your implementation here
    }

    // BONUS (not auto-marked, describe it in PartB_Design.md instead):
    // What happens if the employer never approves work that was genuinely done?
    // Sketch a timeout or dispute mechanism.
}
