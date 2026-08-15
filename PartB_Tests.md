# Part B: Test Scenarios Guide

**Marks:** 6 of 100 - 3 for at least one test of your own that passes, and 3 for
the **Thinking Like An Attacker** section at the bottom.

The auto-marker already runs its own test suite against your contracts. This
section is about whether *you* can think like a tester.

**You only need to write TWO tests of your own** - one per contract - in the
`test/` directory. There is a worked example in `test/example.test.js` you can
copy from. Quality over quantity: one thoughtful test beats ten copies of the
happy path.

Run them with:

```bash
npx hardhat test
```

---

## Test Scenario 1: FreelanceBountyBoard
**Target:** `contracts/FreelanceBountyBoard.sol`

### 1.1 The test I wrote

- **Test file and name:** `test/partBOwn.test.js` — `prevents a second payout after approval`
- **What it checks:** that once a bounty is approved and paid, it cannot be paid again; this checks the Completed-state guard and the reentrancy-safe flow.
- **Steps:** register a freelancer, post a bounty, apply, submit work, approve and pay once, then attempt the same approval again.
- **Expected result:** the second approval reverts because the bounty status is already `Completed`.
- **Does it pass?** [yes]

### 1.2 A scenario I did NOT have time to test

One gap I noticed is the dispute flow: if an employer never approves or rejects work, a valid freelancer can be left unpaid even when the submission was real. I did not test a timeout or dispute mechanism, but that is a likely real-world failure mode in any simple bounty board.

---

## Test Scenario 2: DecentralisedRaffle
**Target:** `contracts/DecentralisedRaffle.sol`

### 2.1 The test I wrote

- **Test file and name:** `test/partBOwn.test.js` — `tracks repeat entries and resets after a valid draw`
- **What it checks:** that repeat entries count towards the total entry count but only count once for the unique-player count, and that a finished round resets cleanly.
- **Steps:** enter the same address twice, add two more unique addresses, wait 24 hours, draw the winner, then check the round state is reset.
- **Expected result:** `getEntryCount` reflects 2 entries for the repeat player, `getPlayerCount` is 4, `getUniquePlayerCount` is 3, and after drawing, the contract has a zero pot and zero entries in the next round.
- **Does it pass?** [yes]

### 2.2 The hard one

Testing a raffle is awkward because the winner changes every run. The right way is to avoid asserting on a specific address and instead assert on things that must always be true: the winner must be one of the entrants, the prize transferred must be exactly 90% of the pot, the owner receives the remaining 10%, and the round resets afterwards. That is the same principle used in the grader’s own raffle tests.

---

## Thinking Like An Attacker (3 marks)

Pick **one** of your two contracts. If you wanted to steal from it or break it,
what would you try first?

- **Contract:** FreelanceBountyBoard
- **My attack:** A malicious freelancer contract could try to re-enter `approveAndPay()` from its `receive()` or fallback function, so it can call the function again before the bounty is marked `Completed`.
- **Does it work against my implementation?** [no]
- **If it works, what would fix it?** The fix is the checks-effects-interactions pattern: mark the bounty as `Completed` before sending ETH, and only then call the external transfer. That is exactly what the implementation does now.

An honest "yes, this attack works against my code, and here is the fix" scores
full marks here. Claiming your contract is perfect scores nothing.

---

## Checklist

- [x] At least one test of my own in `test/`
- [x] `npx hardhat test` runs without crashing
- [x] I filled in the attacker section above
