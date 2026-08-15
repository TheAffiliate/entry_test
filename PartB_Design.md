# Part B: Design Document

**Marks:** 4 of 100 - the **Randomness** section below is read and marked. The
rest of this document is not scored, but it is read when we talk to you, so
answer it properly.

**Section 1: FreelanceBountyBoard**
**Section 2: DecentralisedRaffle**

Short, specific answers beat long vague ones. Three honest sentences score better
than a page of general security talk. If you ran out of time on something, say
so here - describing what you would have done still earns marks. Pretending it
is finished does not.

---

## WHY I BUILT IT THIS WAY

### 1. Data Structure Choices

- Where did you use a `mapping`, and where did you need an array instead?
- How did you record raffle entries so that a player who enters three times has
  three times the chance of winning?
- How did you count unique players separately from total entries?

[Write your response here]

A mapping was used to efficiently track each player's address and the number of times they entered the raffle. This prevents duplication and provides quick lookups for each player's total entries.
An array was needed to record each individual raffle entry to ensure that every entry (even from the same player) has a proportional chance when picking a winner randomly.

Every raffle entry (regardless of who made it) was added to an array, so if a player entered three times, their address would appear three times in the entries array. When a winner is selected, a random index in the array is chosen, giving each entry an equal and independent chance—hence, entering three times multiplies the chance by three.

Unique players were tracked using a mapping(address => bool) or mapping(address => uint) to record addresses seen so far. Each time a player enters and isn't already registered, a counter for unique players is incremented.
Total entries were simply counted by incrementing for every entry, regardless of whether the player was new or returning. This could also be the .length of the entries array.
---

### 2. Security Measures

- **Reentrancy:** show the order of operations in `approveAndPay`. Which line
  updates the status, and which line sends the ETH? Why that order?
- **Access control:** which functions are owner-only or employer-only, and what
  would go wrong without those checks?
- **Input validation:** what did you reject, and where?

[Write your response here]
Reentrancy in approveAndPay
The order is:

Check that the caller is the employer.
Check the bounty is still Submitted.
Update the state first:
bounty.status = Status.Completed;
Only then send ETH:
(bool ok, ) = freelancer.call{value: bounty.amount}("");
The crucial point is that the status update happens before the ETH transfer. If the ETH were sent first, a malicious contract freelancer could trigger its receive() function during the call, re-enter approveAndPay, and drain the contract before the bounty is marked as complete.

The important access checks are:

In the raffle:
selectWinner() is onlyOwner
pause() and unpause() are onlyOwner
In the bounty board:
approveAndPay() is employer-only: require(msg.sender == bounty.employer, ...)
Without these checks, the system breaks:

Anyone could pause or restart the raffle and stop or manipulate entries.
Anyone could choose the winner and steal the prize pool.
Any user could approve a payout for a bounty they did not post, effectively draining the contract.
This is why access control is essential: it prevents unauthorized state changes and protects user funds.

I rejected bad inputs in the key entry points:

In registerFreelancer:
empty skill string rejected, duplicate registration rejected
In postBounty:
zero-value bounty rejected
In applyForBounty:
caller must be registered, bounty must exist and be Open, skill must match the bounty requirement ,duplicate application rejected
In submitWork:
only users who applied may submit
bounty must still be Open
In raffle entry:
entry below MINIMUM_ENTRY rejected, raffle cannot be entered while paused
In selectWinner:
must be after RAFFLE_DURATION, at least 3 unique players required

These checks prevent empty or invalid state, duplicate misuse, and payouts/entries that violate the intended rules.
---

### 3. Randomness - Be Honest Here (4 marks)

You were allowed to use block data for the raffle draw. This section is where
you show you understand what that costs.

- What exactly does your randomness depend on?
- **Who can manipulate it, and how?** Name the actor and the action.
- What would you use in production instead, and why is that better?

My raffle randomness depends on public on-chain values such as `block.timestamp`, `msg.sender`, and the hash of those inputs. In other words, it is not truly random; it is just a pseudo-random value derived from data everyone can see. The block proposer/validator can manipulate this because they decide which block is produced, what timestamp it has, and how transactions are ordered. If that block happens to favour a player, the proposer can choose to include or delay the transaction to bias the draw.

In production I would use Chainlink VRF (or another verifiable random function) instead. VRF gives a cryptographically secure random value that is generated off-chain, published on-chain, and independently verifiable, so no validator can quietly pick the outcome after the fact.

---

### 4. Trade-offs & Future Improvements

- What did you not finish, or knowingly do the quick way?
- What would you add with another day? (dispute resolution, refunds, prize
  tiers, gas optimisation)

I knowingly used the quick version of randomness and did not finish the full refund/edge-case flow. I also skipped a fuller dispute system and more advanced prize logic, because those were not required to satisfy the contract skeleton. With another day, I would add a refund path for low-participation raffles, multiple prize tiers, and some gas-saving cleanup such as reducing repeated storage reads and tightening validation logic.

---

## REAL-WORLD DEPLOYMENT CONCERNS

> [!NOTE]
> These are **written questions only**. You are not deploying anything, and you
> do not need a wallet, a faucet or any test ETH to answer them. Reason it
> through in prose.

### 1. Gas Costs

- Which of your functions is the most expensive, and why?
- Roughly what would it cost a user at 20 gwei, with ETH at $3,000? (Use the
  same arithmetic as Part A Question 2.)
- Is that affordable for the users you would actually be building this for? If
  not, what would you change?

The most expensive function is the raffle draw itself, because it does more state writes than a simple transfer: it reads the entry list, checks the winner condition, emits the event, updates the round state, and pays out ETH. Those storage operations and external transfers make `selectWinner` the highest-cost transaction in this contract.

Using the same arithmetic as the MCQ: if the draw costs roughly 200,000 gas, then 200,000 * 20 gwei = 4,000,000 gwei = 0.004 ETH. At $3,000 per ETH, that is about $12. That is not outrageous for a single raffle, but it would be heavy for a small-value community contest or a low-ticket entry raffle.

For the users I would actually target, I would want to reduce the cost by using fewer storage writes, batching logic, and avoiding expensive per-entry loops wherever possible. For a real product, I would also consider a lower-frequency draw or a Layer 2 to reduce transaction costs.

---

### 2. Scalability

**What happens when the raffle has 10,000 entries?**

- Which part of `selectWinner` gets slower or more expensive as the array grows?
- What breaks first?

As the entry array grows, the winner selection becomes more expensive because the contract has to process more entries and more state reads before calculating a random index and paying the winner. In a real raffle, the first thing that breaks is the block gas limit: the transaction becomes too expensive to fit in a single block, so the draw becomes impractical at large scale.

---

### 3. User Experience

**How would you make this usable for someone who has never held a wallet?**

- What is the hardest step for a first-time user?
- If you *were* deploying this for real, which testnet would you try it on
  first, and how would a tester get test ETH? (Describe it - you are not doing
  it.)

The hardest step for a first-time user is usually setting up a wallet and understanding seed phrases, gas fees, and signing transactions. I would hide as much of that as possible behind a simple onboarding flow: social login, wallet creation in-app, and a guided “fund your wallet” step.

For a real deployment, I would test first on a public testnet such as Sepolia or Holesky. A tester would get test ETH from the network’s faucet, usually by connecting a wallet and requesting funds from a web faucet or a Discord/Telegram faucet for that chain, so they could interact without real money.

---

## MY LEARNING APPROACH

### Resources I Used

Be specific. "The Cyfrin course" is not a resource; "Blockchain Basics, The
Oracle Problem" is. List 3-5.

- Cyfrin Updraft: Blockchain Basics
- Cyfrin Updraft: The Oracle Problem
- Cyfrin Updraft: Reentrancy and Security Patterns
- Solidity docs: function visibility, events, and modifiers
- Ethereum docs: gas, transactions, and block producers

---

### Challenges Faced

- The biggest thing you got stuck on
- How you got unstuck
- What you know now that you did not this morning

The biggest thing I got stuck on was understanding the exact reentrancy pattern and the difference between pseudo-randomness and secure randomness. I got unstuck by tracing the order of checks and effects and by reviewing the examples around `approveAndPay` and the write-on-chain randomness problem. I now understand that the key security rule is checks-effects-interactions, and that block-derived randomness is acceptable only as a simple educational shortcut, not as a production-safe source of entropy.

---

### What I'd Learn Next

I want to learn more about Chainlink VRF, secure wallet UX, and gas optimisation patterns in Solidity. I also want to practise writing more robust access-control patterns and exploring how to design disputes and refunds in a way that remains fair and transparent to users.

---
