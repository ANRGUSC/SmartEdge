# SmartEdge

## What is it?

[SmartEdge](contracts/SmartEdge.sol) is an Ethereum-based smart contract designed to facilitate edge computing. The contract was written using Solidity. Please check out the [doc](doc) folder for more details on the design of the contract.

This work has been accepted into [BIoT 2018](http://cse.stfx.ca/~blockchain2018/BIoT.php), the 1​st​ International Workshop on Blockchain for the Internet of Things, held at the IEEE International Conference on Blockchain in Halifax, Canada. Please see the paper folder for the write-up.

## License

SmartEdge is made available under a permissive license - please see [LICENSE](LICENSE) for details.

## Introduction

We assume that the compute node initiates the contract because it would be expensive for data node to put out the contract since non serious compute nodes may end up wasting the ether of data nodes. It is imagined that there is only one data node and one compute node for the time being

## States of the contract
The entire transaction is imagined as a finite state machine and the states are as follows:
1. Unavailable
2. Available
3. Pending
4. Computing
5. Completed

## Initial state and working
- We start in the unavailable state. The transaction involves the following 
  - jobUrl:-The job url that the data node sends to the compute node 
  - outputUrl:-The url containing output that compute node sends to data node
- All Ether amounts stored in Wei

## Transition Events
1. MadeAvailable() 
2. BidAccepted(address counterparty, string url)
3. JobRejected()
4. JobAccepted(uint startTime) 
5. JobCompleted(uint startTime, uint endTime, string url) 
6. JobTimedOut() 
7. ResultVerified() 
8. ResultTimedOut() 
9. ResultRejected()

## Modifiers
1. modifier onlyBy(address _address): 
 - Checks if function being called is the creator of the contract 
2.  modifier onlyAfter(uint _time): 
 - Checks if function being called is called before a particular time
3.  modifier atState(States _state)
 - Checks if function being called is not in the proper state

## Functions
1. function setAvailable(uint bid):
 - State is set to available. Owner calls by sending some amount in the unavailable state. 
 - If there is insufficient balance, an error is displayed, a min escrow amount is transfered to msg.sender

2. function acceptBid(string url) 
 - Accept a bid only with an ether amount and in the available state. 
 - The value must be > than the Minimum specified amount. If bid accepted, go to next state

3. function jobRejected() 
 - Owner can decide to reject transaction in the pending state and state is set to available if job is rejected

4. function jobAccepted() 
 - Owner decides if the job is accepted in pending state, if job is accepted, it transitions to Computing state and a JobAccepted event is broadcasted

5. function jobCompleted(string url) public:
 - Function can be called only by owner in Computing state. When job gets completed, state changes to 'Completed' and a jobCompleted event is broadcasted and the output url is obtained from compute node

6. function jobTimedOut() public
 - If the counterparty takes longer than expected, the escrow amount is refunded and JobTimedOut event is broadcasted

7. function resultVerified() public
 - Once the result is computed, the owner calls this function to charge the counterparty, state is set to unavialable and a resultverified event is broadcasted

8. function resultTimedOut() public
 - If the job takes longer than expected the counter party is charged, the state is set to Unavailable and a resultTimeout event is broadcasted. Called when in Completed state

9. function resultRejected() public 
 - Called only by counterparty, the escrow amount of counterparty is refunded, other party is penalised, state changes to Unavailable and rejection is broadcasted

10. function chargeCounterparty() private 
 - Charge counterparty for job 
 - Transfer amount to owner. If counterparty exceeds the escrow limit entire escrow amount is sent to owner else the cost is deducted from the escrow amount

11. function refundCounterparty() 
 - Refund escrow to counterparty. If counterparty has no balance, exit, else transfer the ether to the counter party and set counter party balance to 0
