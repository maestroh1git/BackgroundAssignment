// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
//using hardhat/console.sol to display things to the console
import "hardhat/console.sol";

contract Purchase {
    //define variables
    uint public value;
    uint public currentTime = block.timestamp;
    address payable public seller;
    address payable public buyer;

    //define enumerable states
    enum State { Created, Locked, Inactive }
    // The state variable has a default value of the first member, `State.created`
    State public state;

    modifier condition(bool condition_) {
        require(condition_);
        _;
    }

    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();
    /// The purchase conditions have to be met
    error UnableToCompletePurchase();

    modifier onlyBuyer() {
        if (msg.sender != buyer)
            revert OnlyBuyer();
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller)
            revert OnlySeller();
        _;
    }

    modifier inState(State state_) {
        if (state != state_)
            revert InvalidState();
        _;
    }

    modifier onlyBuyerInRealTime() {
        if (msg.sender != buyer || block.timestamp <= ( currentTime + 5 minutes))
            revert UnableToCompletePurchase();
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    // Ensure that `msg.value` is an even number.
    // Division will truncate if it is an odd number.
    // Check via multiplication that it wasn't an odd number.
    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        if ((2 * value) != msg.value)
            revert ValueNotEven();
        console.log("Time of deployment is given as (unix timestamp)-", currentTime);
    }

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.
    function abort()
        external
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        // We use transfer here directly. It is
        // reentrancy-safe, because it is the
        // last call in this function and we
        // already changed the state.
        seller.transfer(address(this).balance);
    }

    /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase()
        external
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
        console.log("Purchase confirmed", currentTime);
    }

    /// Confirm that you (the buyer) received the item and refunds the seller, i.e.
    /// This will release the locked ether and pays back the locked funds of the seller.

    /// This function refunds the seller, i.e.


    function completePurchase()
        external
        inState(State.Locked)
        onlyBuyerInRealTime
    {

        state = State.Inactive; 

        buyer.transfer(value);
        console.log("Buyer funds has been transferred-", value);
        seller.transfer(3 * value);
        console.log("Seller funds has been transferred-", 3*value);

        emit ItemReceived();
        emit SellerRefunded();

        console.log("Logging complete purchase time as (unix timestamp) -", currentTime);
    }
}