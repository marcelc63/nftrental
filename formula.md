// Stock purchase formula without dilution.
// User can stake a token, but must pay to get a share of the treasury.
// Staker can get his money back at any time when unstaking as the value of his stock is the same as the stoke purchase amount.

    // Example calculation (sharePrice = treasury / totalOutstandingShares)
    // Treasury: 0Eth | totalOutstandingShares: 0
    // User A stakes 2 Access Pass
    // sharePrice = 0 / 0 = 0
    // Stakes for free

    // Renter X rents 1 Pass for 1Eth
    // Treasury: 1Eth | totalOutstandingShares: 2 | sharePrice: 0.5Eth

    // User B Stakes 1 Access Pass
    // sharePrice = 1Eth / 2 = 0.5E
    // Stakes 1 pass + needs to pay 0.5E to buy share in treasury

    // Treasury: 1.5Eth | totalShareOutstanding: 3 | sharePrice: 0.5Eth

    // User A unstakes 2 passes
    // sharePrice = 1.5Eth / 3 = 0.5E
    // totalPayoutPrice = shares * sharePrice = 2 * 0.5 = 1Eth

    // Treasury: 0.5E | totalOutstandingShares: 1 | sharePrice: 0.5Eth

    // User B unstakes 1 pass
    // shareprice = 0.5E / 1 = 0.5E
    // totalPayoutPrice = shares * sharePrice = 1 * 0.5 = 0.5E
    // User get's back his investment of 0.5E

2.5 / 3

// Treasury: 0ETH
// A stakes 2 pass when its 0ETH

// renter x rents 1 pass for 1 eth
// Share price for rent A = 1 - 0 = 1 / 2
// sharePrice: 0.5

// B stakes pass for 1 pass
// Stakes when treasury is at 1 eth
// Total Stake = 3

// Renter rent for 1 eth
// Total treasury = 2
// A shareprice = 2 - 0 = 2/3

Renter B for 2 eth
total treasury 2
B sharePrice = 2 - 1 = 1 / 3
