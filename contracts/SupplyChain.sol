// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;
  uint public skuCount;
  mapping(uint => Item) public items;

  enum State { ForSale, Sold, Shipped, Received }
  struct Item { 
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier paidEnough(uint _sku) { 
    require(msg.value >= items[_sku].price); 
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    (bool success, ) = items[_sku].buyer.call.value(amountToRefund)("");
    require(success, "Transfer failed.");
  }

  modifier isSeller(uint _sku) {
    require(msg.sender == items[_sku].seller);
    _;
  }

  modifier isBuyer(uint _sku) {
    require(msg.sender == items[_sku].buyer);
    _;
  }

  modifier forSale(uint _sku) {
    require(items[_sku].state == State.ForSale && items[_sku].price > 0);
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold);
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped);
    _;
  }

  modifier received(uint _sku) {
    require(items[_sku].state == State.Received);
    _;
  }
  constructor() public {
    // 1. Set the owner to the transaction sender
    // 2. Initialize the sku count to 0. Question, is this necessary? Answer: NO
    owner = msg.sender;
    skuCount = 0;
  }

  // 1. Create a new item and put in array
  // 2. Increment the skuCount by one
  // 3. Emit the appropriate event
  // 4. return true
  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: msg.sender,
      buyer: address(0)
    });

    skuCount += 1;
    emit LogForSale(skuCount); 
    return true;
  }

  // Implement this buyItem function. 
  // 1. it should be payable in order to receive refunds
  // 2. this should transfer money to the seller, 
  // 3. set the buyer as the person who called this transaction, 
  // 4. set the state to Sold. 
  // 5. this function should use 3 modifiers to check 
  //    - if the item is for sale, 
  //    - if the buyer paid enough, 
  //    - check the value after the function is called to make 
  //      sure the buyer is refunded any excess ether sent. 
  // 6. call the event associated with this function!
  function buyItem(uint _sku) public payable forSale(_sku) paidEnough(_sku) checkValue(_sku) {
    (bool success, ) = items[_sku].seller.call.value(items[_sku].price)("");
    require(success, "Transfer failed.");
    items[_sku].buyer = msg.sender;
    items[_sku].state = State.Sold;
    emit LogSold(_sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint _sku) public sold(_sku) isSeller(_sku) {
    items[_sku].state = State.Shipped;
    emit LogShipped(_sku);
  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint _sku) public shipped(_sku) isBuyer(_sku) {
    items[_sku].state = State.Received;
    emit LogReceived(_sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view 
  returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;

    return (name, sku, price, state, seller, buyer);
  }
}