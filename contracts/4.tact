import "@stdlib/deploy";

/*
  TASK 4 - NFT locker
  Implement a smart contract that will lock NFT for a period of time specified by the owner.
  Smart conrtact should contain logic to process following messages and getters: 

  Messages: 
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If the smart contract already holds an nft then return the incoming nft back to the sender
  * NftWithdrawal
   - Request withdrawal of the locked nft
   - If sender is not the owner (that came from OwnershipAssigned as prevOwner address) then throw "Invalid sender" 
   - If time has not passed then send message back to the sender with the comment "NFT is still locked" according to the TON's "message with text comment" standard 
   - Otherwise (all good) send the locked nft back to the owner with all the remaining TON balance
   Note that the order of checks is important
   (in case: "sender is not the owner" and "time has not passed" at the same time, "Invalid sender" error takes priority)

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get the address of the locked nft 
  * owner
   - get the owner of the locked nft (that came from OwnershipAssigned as prevOwner)
*/

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64; 
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract Task4 with Deployable {

  seed: Int as uint128;
  prevOwner: Address=myAddress();
  nftAddress: Address=myAddress();
  waitTime: Int as uint32=0;
  ini: Int as uint32=0;
  ocupate: Bool;

  init(seed: Int) {
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
    self.ocupate=false;
  }

  receive(msg: OwnershipAssigned) {
    require(self.ocupate==false,"");
    self.ini=now();
    self.ocupate=true;
    self.nftAddress=sender();
    self.prevOwner=msg.prevOwner;
    self.waitTime=msg.forwardPayload.loadUint(32);
  }

  receive(msg: NftWithdrawal) {
    require(self.ocupate==true,"");
    require(self.prevOwner==snder,"Invalid sender");
    require(self.waitTime<=now()-self.ini,"NFT is still locked");
    self.ocupate=false;
    send(SendParameters{
      to: sender(),
      value: 0,
      mode: 64,
      body: Transfer{
        queryId: msg.queryId,
        newOwner: self.prevOwner,
        responseDestination: myAddress(), 
        customPayload: null,
        forwardAmount: myBalance(), 
        forwardPayload: emptySlice()
      }.asCell()
    });
  }

  get fun time(): Int {
    return self.waitTime-now()+self.ini;
  }

  get fun nft(): Address? {
    return self.nftAddress;
  }

  get fun owner(): Address? {
    return self.prevOwner;
  }
}