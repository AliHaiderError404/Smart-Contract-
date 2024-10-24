// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleBettingContract {
    // Enum for betting states
    enum BettingState { Open, Closed, Resolved }
    BettingState public state;

    // Enum for teams
    enum Team { None, TeamA, TeamB }

    // Struct to store details of each bet
    struct Bet {
        uint amount;
        Team selectedTeam;
        bool withdrawn;
    }

    // Mapping to track bets by users
    mapping(address => Bet) public bets;

    // Variables to track total bet amounts for each team
    uint public totalBetAmountTeamA;
    uint public totalBetAmountTeamB;

    // The contract owner
    address public owner;

    // The winning team (set after resolution)
    Team public winningTeam;

    // Events to log important actions
    event BetPlaced(address indexed user, Team team, uint amount);
    event BetResolved(Team winner);
    event WinningsWithdrawn(address indexed user, uint amount);

    // Constructor to set the owner and initial state
    constructor() {
        owner = msg.sender;  // The person who deploys the contract is the owner
        state = BettingState.Open;  // Initially, betting is open
    }

    // Function to place a bet (payable, meaning users send ETH when calling this)
    function placeBet(Team _team) external payable {
        require(state == BettingState.Open, "Betting is not open");
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(bets[msg.sender].amount == 0, "You have already placed a bet");
        require(_team == Team.TeamA || _team == Team.TeamB, "Invalid team selected");

        // Save the bet details for the user
        bets[msg.sender] = Bet(msg.value, _team, false);

        // Add to the total bets for the selected team
        if (_team == Team.TeamA) {
            totalBetAmountTeamA += msg.value;
        } else {
            totalBetAmountTeamB += msg.value;
        }

        // Emit the BetPlaced event
        emit BetPlaced(msg.sender, _team, msg.value);
    }

    // Function to resolve the bet (only owner can call this function)
    function resolveBet(Team _winningTeam) external {
        require(msg.sender == owner, "Only the owner can resolve the bet");
        require(state == BettingState.Closed, "Betting must be closed first");
        require(_winningTeam == Team.TeamA || _winningTeam == Team.TeamB, "Invalid winning team");

        // Set the winning team and change state to Resolved
        winningTeam = _winningTeam;
        state = BettingState.Resolved;

        // Emit the BetResolved event
        emit BetResolved(_winningTeam);
    }

    // Function to close the betting (only owner can call this function)
    function closeBetting() external {
        require(msg.sender == owner, "Only the owner can close the betting");
        require(state == BettingState.Open, "Betting is already closed or resolved");

        // Change the state to Closed
        state = BettingState.Closed;
    }

    // Function to withdraw winnings (if user bet on the winning team)
    function withdrawWinnings() external {
        require(state == BettingState.Resolved, "Betting has not been resolved yet");

        Bet storage userBet = bets[msg.sender];
        require(userBet.amount > 0, "You have not placed a bet");
        require(!userBet.withdrawn, "Winnings already withdrawn");
        require(userBet.selectedTeam == winningTeam, "You did not bet on the winning team");

        uint payout;
        // Calculate the payout based on total bet amounts
        if (winningTeam == Team.TeamA) {
            payout = (userBet.amount * (totalBetAmountTeamA + totalBetAmountTeamB)) / totalBetAmountTeamA;
        } else {
            payout = (userBet.amount * (totalBetAmountTeamA + totalBetAmountTeamB)) / totalBetAmountTeamB;
        }

        userBet.withdrawn = true;  // Mark that the user has withdrawn their winnings
        payable(msg.sender).transfer(payout);  // Transfer winnings to the user

        // Emit the WinningsWithdrawn event
        emit WinningsWithdrawn(msg.sender, payout);
    }

    // Fallback function to prevent accidental ETH transfers
    receive() external payable {
        revert("Direct transfers not allowed");
    }
}
