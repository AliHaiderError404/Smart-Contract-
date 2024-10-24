// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BettingContract {
    // Enum to define betting states
    enum BettingState { Open, Closed, Resolved }
    BettingState public state;

    // Enum to define teams
    enum Team { None, TeamA, TeamB }

    // Struct to store details of each bet
    struct Bet {
        uint amount;
        Team selectedTeam;
        bool withdrawn;
    }

    // Mapping to track bets placed by each user
    mapping(address => Bet) public bets;

    // Variables to track total bet amounts for each team
    uint public totalBetAmountTeamA;
    uint public totalBetAmountTeamB;

    // Owner of the contract
    address public owner;

    // Variable to store the winning team
    Team public winningTeam;

    // Events for logging actions
    event BetPlaced(address indexed user, Team team, uint amount);
    event BetResolved(Team winningTeam);
    event WinningsWithdrawn(address indexed user, uint amount);

    // Constructor to set the contract owner and open the betting round
    constructor() {
        owner = msg.sender;
        state = BettingState.Open; // Betting is initially open
    }

    // Modifier to restrict function access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Function for users to place a bet (payable)
    function placeBet(Team _team) external payable {
        require(state == BettingState.Open, "Betting is not open");
        require(bets[msg.sender].amount == 0, "You have already placed a bet");
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(_team == Team.TeamA || _team == Team.TeamB, "Invalid team selection");

        // Record the bet
        bets[msg.sender] = Bet({
            amount: msg.value,
            selectedTeam: _team,
            withdrawn: false
        });

        // Update total bet amounts for the teams
        if (_team == Team.TeamA) {
            totalBetAmountTeamA += msg.value;
        } else {
            totalBetAmountTeamB += msg.value;
        }

        emit BetPlaced(msg.sender, _team, msg.value);
    }

    // Function to resolve the bet and declare the winning team (only owner can call this)
    function resolveBet(Team _winningTeam) external onlyOwner {
        require(state == BettingState.Closed, "Betting must be closed to resolve");
        require(_winningTeam == Team.TeamA || _winningTeam == Team.TeamB, "Invalid winning team");

        // Set the winning team and change the state
        winningTeam = _winningTeam;
        state = BettingState.Resolved;

        emit BetResolved(_winningTeam);
    }

    // Function to close the betting (only owner can call this)
    function closeBetting() external onlyOwner {
        require(state == BettingState.Open, "Betting is already closed or resolved");
        state = BettingState.Closed;
    }

    // Function for users to withdraw their winnings after the bet is resolved
    function withdrawWinnings() external {
        require(state == BettingState.Resolved, "Betting has not been resolved yet");

        Bet storage userBet = bets[msg.sender];
        require(userBet.amount > 0, "No bet placed");
        require(!userBet.withdrawn, "Winnings already withdrawn");
        require(userBet.selectedTeam == winningTeam, "You did not bet on the winning team");

        uint payout;
        if (winningTeam == Team.TeamA) {
            payout = (userBet.amount * (totalBetAmountTeamA + totalBetAmountTeamB)) / totalBetAmountTeamA;
        } else {
            payout = (userBet.amount * (totalBetAmountTeamA + totalBetAmountTeamB)) / totalBetAmountTeamB;
        }

        userBet.withdrawn = true; // Mark winnings as withdrawn
        payable(msg.sender).transfer(payout); // Transfer the winnings

        emit WinningsWithdrawn(msg.sender, payout);
    }

    // Fallback function to prevent accidental ETH transfers
    receive() external payable {
        revert("Direct transfers not allowed");
    }
}
