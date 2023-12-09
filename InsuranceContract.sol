//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./InsuranceContractPool.sol";

contract InsuranceContract {
    uint id;
    struct payment {
        uint amount;
        bool done;
    }

    struct expertOpinion {
        bool givenOpinion;
        uint amount;
        bool given;
        address expertAddress;
    }

    bool public accidentHappened = false;

    expertOpinion public expert;
    address public insurable;
    uint public startDate;
    uint public endDate;
    // date => payment
    mapping(uint => payment) public paymentSchedule;
    address public pool;
    uint[] dates;
    uint paymentAmount;

    constructor(
        address _pool,
        address _insurable,
        address _expert,
        uint _startDate,
        uint _endDate,
        uint _totalAmount,
        uint _amountOfPayments,
        uint _id) {
        id = _id;

        insurable = _insurable;
        expert = expertOpinion(false, 0, false, _expert);
        startDate = _startDate;
        endDate = _endDate;
        createPaymentSchedule(_startDate, _endDate, _totalAmount, _amountOfPayments);
        pool = _pool;
    }

    // Makes sure that only insurable can access
    modifier onlyInsurable() {
        require(msg.sender == insurable, "Only the insurer can access this.");
        _;
    }

    // Makes sure that only yhe pools address can access that function
    modifier onlyPool() {
        require(msg.sender == pool, "Only the pool can access this.");
        _;
    }

    function notifyOfAccident() public onlyInsurable {
        accidentHappened = true;
    }

    // Function to create a payment schedule
    function createPaymentSchedule(uint _startDate, uint _endDate, uint _totalAmount, uint amountOfPayments) private {
        require(amountOfPayments > 0, "Number of payments should be greater than zero");
        require(_endDate > _startDate, "End date should be greater than start date");
        uint gapBetweenPayments = (_endDate - _startDate) / amountOfPayments;
        paymentAmount = _totalAmount / amountOfPayments;

        for (uint i = 1; i <= amountOfPayments; i++) {
            uint paymentDate = _startDate + gapBetweenPayments * i;
            dates.push(paymentDate);
            paymentSchedule[paymentDate] = payment(paymentAmount, false);
        }
    }

    // Updates the experts opinion
    function updateExpertOpinion(address _expert, bool _givenOpinion, uint amount) public onlyPool {
        require(expert.expertAddress == _expert, "Expert does not exist in the mapping");
        expert.givenOpinion = _givenOpinion;
        expert.amount = amount;
        if (expert.givenOpinion) {
            requestPoolToMakePayment();
        }
    }

    // Makes a request to the pool to payout
    function requestPoolToMakePayment() private {
        InsuranceContractPool poolContract = InsuranceContractPool(pool);
        poolContract.compensateDamage(expert.amount, insurable);
    }

    function getPaymentDates() public onlyInsurable view returns(uint[] memory) {
        return dates;
    }

    function getPaymentAmount() public onlyInsurable view returns(uint) {
        return paymentAmount;
    }

    // function the user can call to make a payment
    function makePayment(uint date) payable public onlyInsurable {
        require(msg.value == getPaymentAmount(), "Value must be the same amount as payment amount.");
        require(!paymentSchedule[date].done, "Payment for that date is already done");
        paymentSchedule[date].done = true;

        // Transfer the payment amount to the insurable
        InsuranceContractPool(pool).deposit{value: msg.value}();
    }
}

// https://sepolia.etherscan.io/address/0x7c1890Ca5ceFC43fB693a8D8524568dAb6608A15 etherscan link