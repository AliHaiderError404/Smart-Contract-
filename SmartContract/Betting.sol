// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BettingContract {
    // Enum to define the state of the bet
    enum BettingState { Open, Closed, Resolved }
    BettingState public state;

    // Enum for teams
    enum Team { None, TeamA, TeamB }

    // Struct to store bet details
    struct Bet {
        uint amount;
        Team selectedTeam;
        bool withdrawn;
    }

    // Mapping to store bets placed by each user
    mapping(address => Bet) public bets;
    
    // Variables for tracking total bets
    uint public totalBetAmountTeamA;
    uint public totalBetAmountTeamB;

    // Owner of the contract
    address public owner;

    // Variable to store the winning team
    Team public winningTeam;

    // Events for logging actions
    event BetPlaced(address indexed user, Team indexed team, uint amount);
    event BetResolved(Team winningTeam);
    event WinningsWithdrawn(address indexed user, uint amount);

    // Constructor sets the owner and initial state to Open
    constructor() {
        owner = msg.sender;
        state = BettingState.Open;
    }

    // Function to place a bet (payable to send ETH)
    function placeBet(Team _team) external payable {
        require(state == BettingState.Open, "Betting is not open");
        require(bets[msg.sender].amount == 0, "You have already placed a bet");
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(_team == Team.TeamA || _team == Team.TeamB, "Invalid team selected");

        // Record the bet
        bets[msg.sender] = Bet({
            amount: msg.value,
            selectedTeam: _team,
            withdrawn: false
        });

        // Track total bet amounts for each team
        if (_team == Team.TeamA) {
            totalBetAmountTeamA += msg.value;
        } else {
            totalBetAmountTeamB += msg.value;
        }

        emit BetPlaced(msg.sender, _team, msg.value);
    }

    // Function for the owner to resolve the bet and declare the winning team
    function resolveBet(Team _winningTeam) external {
        require(msg.sender == owner, "Only the owner can call this function"); // Owner restriction logic here
        require(state == BettingState.Closed, "Betting must be closed to resolve");
        require(_winningTeam == Team.TeamA || _winningTeam == Team.TeamB, "Invalid winning team");
        state = BettingState.Resolved;
        winningTeam = _winningTeam;
        emit BetResolved(_winningTeam);
    }

    // Function to close betting (only owner)
    function closeBetting() external {
        require(msg.sender == owner, "Only the owner can call this function"); // Owner restriction logic here
        require(state == BettingState.Open, "Betting is already closed or resolved");
        state = BettingState.Closed;
    }

    // Function for users to withdraw winnings
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

        userBet.withdrawn = true;
        payable(msg.sender).transfer(payout);
        emit WinningsWithdrawn(msg.sender, payout);
    }

    // Error handling with require statements (example for testing)
    function checkBetState() public view {
        require(state == BettingState.Open, "Betting is not open");
    }

    // Fallback function to prevent accidental ETH transfers
    receive() external payable {
        revert("Direct transfers not allowed");
    }
}
