pragma solidity ^0.4.23;

contract Compute {
  address public owner = msg.sender;
  address public counterparty;

  enum States {
    Unavailable,
    Available,
    Pending,
    Computing,
    Completed
  }
  States public state = States.Unavailable;

  // Owner's compute price per unit time (seconds)
  uint public currentBid;

  string public jobUrl;
  string public outputUrl;

  uint public currentJobStartTime;
  uint public currentJobEndTime;

  // All Ether amounts stored in Wei
  uint public constant MinEscrowFromComputeNode = 1e18;
  uint public computeNodeEscrow = 0;

  uint public constant MinEscrowFromCounterparty = 1e18;
  uint public counterpartyEscrow = 0;

  uint constant Timeout = 10 seconds;
  uint constant Penalty = 1e16;

  // Transition Events
  event MadeAvailable();
  event BidAccepted(address counterparty, string url);
  event JobRejected();
  event JobAccepted(uint startTime);
  event JobCompleted(uint startTime, uint endTime, string url);
  event JobTimedOut();
  event ResultVerified();
  event ResultTimedOut();
  event ResultRejected();

  constructor() public {
  }

  modifier onlyBy(address _address)
  {
    require(msg.sender == _address, 'Sender not authorized');
    _;
  }

  modifier onlyAfter(uint _time) {
    require(now >= _time, 'Function called too early.');
    _;
  }

  modifier atState(States _state)
  {
    require(state == _state, 'Not in proper state');
    _;
  }

  function setAvailable(uint bid) public payable
    onlyBy(owner)
    atState(States.Unavailable)
  {
    computeNodeEscrow += msg.value;
    require(
      computeNodeEscrow >= MinEscrowFromComputeNode, 
      'Insufficient balance for Compute Node'
    );

    // Return any excess escrow
    if (computeNodeEscrow > MinEscrowFromComputeNode) {
      msg.sender.transfer(computeNodeEscrow - MinEscrowFromComputeNode);
      computeNodeEscrow = MinEscrowFromComputeNode;
    }

    currentBid = bid;
    state = States.Available;
    emit MadeAvailable();
  }

  function acceptBid(string url) public payable
    atState(States.Available)
  {
    counterpartyEscrow += msg.value;
    require(
      counterpartyEscrow >= MinEscrowFromCounterparty, 
      'Insufficient balance for Counterparty'
    );

    counterparty = msg.sender;
    jobUrl = url;
    state = States.Pending;
    emit BidAccepted(counterparty, url);
  }

  function jobRejected() public
    onlyBy(owner)
    atState(States.Pending)
  {
    refundCounterparty();
    counterparty = 0;
    state = States.Available;
    emit JobRejected();
  }

  function jobAccepted() public
    onlyBy(owner)
    atState(States.Pending)
  {
    currentJobStartTime = now;
    state = States.Computing;
    emit JobAccepted(currentJobStartTime);
  }

  function jobCompleted(string url) public
    onlyBy(owner)
    atState(States.Computing)
  {
    currentJobEndTime = now;
    outputUrl = url;

    state = States.Completed;
    emit JobCompleted(currentJobStartTime, currentJobEndTime, url);
  }

  function jobTimedOut() public
    atState(States.Computing)
    onlyAfter(currentJobStartTime + Timeout)
  {
    refundCounterparty();
    counterparty = 0;
    state = States.Unavailable;
    emit JobTimedOut();
  }

  function resultVerified() public
    onlyBy(counterparty)
    atState(States.Completed)
  {
    chargeCounterparty();
    refundCounterparty();
    counterparty = 0;

    state = States.Unavailable;
    emit ResultVerified();
  }

  function resultTimedOut() public
    atState(States.Completed)
    onlyAfter(currentJobEndTime + Timeout)
  {
    chargeCounterparty();
    refundCounterparty();
    counterparty = 0;

    state = States.Unavailable;
    emit ResultTimedOut();
  }

  function resultRejected() public
    onlyBy(counterparty)
    atState(States.Completed)
  {
    refundCounterparty();

    counterparty.transfer(Penalty);
    computeNodeEscrow -= Penalty;

    counterparty = 0;
    state = States.Unavailable;
    emit ResultRejected();
  }

  // Charge counterparty for job
  function chargeCounterparty() private
  {
    uint cost = (currentJobEndTime - currentJobStartTime) * currentBid;
    if (cost > counterpartyEscrow) {
      cost = counterpartyEscrow;
    }

    owner.transfer(cost);
    counterpartyEscrow -= cost;
  }

  // Refund escrow back to counterparty
  function refundCounterparty() private
  {
    assert(counterparty != 0);

    if (counterpartyEscrow > 0) {
      counterparty.transfer(counterpartyEscrow);
    }
    counterpartyEscrow = 0;
  }

}
