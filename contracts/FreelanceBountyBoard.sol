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

    struct Freelancer {
        string skill;
    }

    struct Bounty {
        address employer;
        string description;
        string skillRequired;
        uint256 amount;
        Status status;
    }

    // --- Events (the marker checks these are emitted) ---
    event FreelancerRegistered(address indexed freelancer, string skill);
    event BountyPosted(uint256 indexed bountyId, address indexed employer, uint256 amount);
    event AppliedForBounty(uint256 indexed bountyId, address indexed freelancer);
    event WorkSubmitted(uint256 indexed bountyId, address indexed freelancer, string submissionUrl);
    event BountyPaid(uint256 indexed bountyId, address indexed freelancer, uint256 amount);

    address public owner;
    uint256 public bountyCount;

    mapping(address => Freelancer) public freelancers;
    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => mapping(address => bool)) private _applied;

    constructor() {
        owner = msg.sender;
    }

    function registerFreelancer(string calldata skill) external {
        require(bytes(skill).length != 0, "Skill cannot be empty");
        require(bytes(freelancers[msg.sender].skill).length == 0, "Freelancer already registered");

        freelancers[msg.sender].skill = skill;
        emit FreelancerRegistered(msg.sender, skill);
    }

    function postBounty(string calldata description, string calldata skillRequired)
        external
        payable
        returns (uint256)
    {
        require(msg.value > 0, "Bounty amount must be greater than zero");

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

    function applyForBounty(uint256 bountyId) external {
        require(bytes(freelancers[msg.sender].skill).length != 0, "Caller is not a registered freelancer");

        Bounty storage bounty = bounties[bountyId];
        require(bounty.employer != address(0), "Bounty does not exist");
        require(bounty.status == Status.Open, "Bounty is not open");
        require(
            keccak256(bytes(freelancers[msg.sender].skill)) == keccak256(bytes(bounty.skillRequired)),
            "Freelancer skill does not match bounty requirement"
        );
        require(!_applied[bountyId][msg.sender], "Freelancer has already applied for this bounty");

        _applied[bountyId][msg.sender] = true;
        emit AppliedForBounty(bountyId, msg.sender);
    }

    function submitWork(uint256 bountyId, string calldata submissionUrl) external {
        require(_applied[bountyId][msg.sender], "Freelancer has not applied for this bounty");

        Bounty storage bounty = bounties[bountyId];
        require(bounty.status == Status.Open, "Bounty is not open");

        bounty.status = Status.Submitted;
        emit WorkSubmitted(bountyId, msg.sender, submissionUrl);
    }

    function approveAndPay(uint256 bountyId, address freelancer) external {
        Bounty storage bounty = bounties[bountyId];
        require(msg.sender == bounty.employer, "Only the employer can approve and pay");
        require(bounty.status == Status.Submitted, "Bounty is not submitted");

        bounty.status = Status.Completed;
        (bool ok, ) = freelancer.call{value: bounty.amount}("");
        require(ok, "Transfer failed");

        emit BountyPaid(bountyId, freelancer, bounty.amount);
    }

    function isRegistered(address freelancer) external view returns (bool) {
        return bytes(freelancers[freelancer].skill).length != 0;
    }

    function getSkill(address freelancer) external view returns (string memory) {
        return freelancers[freelancer].skill;
    }

    function hasApplied(uint256 bountyId, address freelancer) external view returns (bool) {
        return _applied[bountyId][freelancer];
    }

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
        Bounty storage bounty = bounties[bountyId];
        return (
            bounty.employer,
            bounty.description,
            bounty.skillRequired,
            bounty.amount,
            bounty.status
        );
    }

    function disputeMechanism(uint256 bountyId) external {
        Bounty storage bounty = bounties[bountyId];
        require(msg.sender == bounty.employer, "Only the employer can initiate a dispute");
        require(bounty.status == Status.Submitted, "Bounty is not in submitted status");
        bounty.status = Status.Open;
    }
}
