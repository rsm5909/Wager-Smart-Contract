pragma solidity >0.4.99;

contract Betting{
  //https://medium.com/coinmonks/create-a-sports-betting-dapp-on-the-ethereum-blockchain-part-1-1f69f908b939
    
  uint256 public minimumBet;
  uint256 public totalBetOne;
  uint256 public totalBetTwo;
  uint256 public numberOfBets;
  uint256 public maxAmountOfBets = 1000;
  uint256 public strike = 29245;
  uint256 public start;
  uint256 public numdays = 1;
  uint256 public deadline = 1567807200;
  uint256 public cutoff = 1567546200;
  address private owner;
  address payable[] public players;
   
  struct Player {
    uint256 amountBet;
    uint16 teamSelected;
  }
   
  // Address of the player and => the user info   
  mapping(address => Player) public playerInfo;
  
  constructor(uint256 _start, uint256 _deadline, uint256 _cutoff, uint256 _strike) public {
    owner = msg.sender;
    minimumBet = 100000000000000;
    start = _start;
    deadline = _deadline;
    cutoff= _cutoff;
    strike= _strike;
  }
   
  //check if player already exists
  function checkPlayerExists(address player) public view returns(bool){
    for(uint256 i = 0; i < players.length; i++){
      if(players[i] == player) return true;
    }
    return false;
  }
   
  function Bet(uint8 _teamSelected) public payable {
    uint256 ts = now;
    require (ts < cutoff);
    //The first require is used to check if the player already exist
    require(!checkPlayerExists(msg.sender));
    //The second one is used to see if the value sended by the player is 
    //Higher than the minum value
    require(msg.value >= minimumBet);
    
    //We set the player informations : amount of the bet and selected team
    playerInfo[msg.sender].amountBet = msg.value;
    playerInfo[msg.sender].teamSelected = _teamSelected;
    
    //then we add the address of the player to the players array
    players.push(msg.sender);
    
    //at the end, we increment the stakes of the team selected with the player bet
    if ( _teamSelected == 1){
      totalBetOne += msg.value;
    }
    else{
      totalBetTwo += msg.value;
    }
  }
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
   
  function distributePrizes(uint256 spot) public onlyOwner {
    uint256 teamWinner;
    uint256 time = now;
    require(time > deadline);
    if (spot > strike){
       teamWinner = 1;
    } else {
       teamWinner = 2;
    }
    address payable[1000] memory winners;
    //We have to create a temporary in memory array with fixed size
    //Let's choose 1000
    
    uint256 count = 0; // This is the count for the array of winners
    uint256 LoserBet = 0; //This will take the value of all losers bet
    uint256 WinnerBet = 0; //This will take the value of all winners bet
    address add;
    uint256 bet;
    address payable playerAddress;
    //loop through the player array to check who selected the winner team
    for(uint256 i = 0; i < players.length; i++){
      playerAddress = players[i];
      //If the player selected the winner team
      //We add his address to the winners array
      if(playerInfo[playerAddress].teamSelected == teamWinner){
        winners[count] = playerAddress;
        count++;
      }
    }
    //We define which bet sum is the Loser one and which one is the winner
    if ( teamWinner == 1){
      LoserBet = totalBetTwo;
      WinnerBet = totalBetOne;
    }
    else{
      LoserBet = totalBetOne;
      WinnerBet = totalBetTwo;
    }
    //We loop through the array of winners, to give ethers to the winners
    for(uint256 j = 0; j < count; j++){
      // Check that the address in this fixed array is not empty
      if(winners[j] != address(0))
        add = winners[j];
        bet = playerInfo[add].amountBet;
        //Transfer the money to the user
        winners[j].transfer((bet*(10000+(LoserBet*10000/WinnerBet)))/10000 );
    }
    
    delete playerInfo[playerAddress]; // Delete all the players
    players.length = 0; // Delete all the players array
    LoserBet = 0; //reinitialize the bets
    WinnerBet = 0;
    totalBetOne = 0;
    totalBetTwo = 0;
  }

  function AmountOne() public view returns(uint256){
    return totalBetOne;
  }
   
  function AmountTwo() public view returns(uint256){
    return totalBetTwo;
  }
  
  function TotalBets() public view returns(uint256){
    return totalBetOne + totalBetTwo;
  }
}