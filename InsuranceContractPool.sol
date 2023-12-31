//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./InsuranceContract.sol";

contract InsuranceContractPool {
    uint public maxWeightOfContract;
    uint public maxPercentageOfAllContracts;
    address private owner;
    uint public amountInsuredOut;
    uint public totalAmount;
    mapping(address => mapping(address => bool)) public insuranceExperts;
    address[] public insuranceContractAddresses;


    struct insurance {
        InsuranceContract insuranceContract;
        uint amount;
    }

    mapping(address => insurance) public insurances;

    constructor(address _owner, uint _maxWeightOfContract, uint _maxPercentageOfAllContracts) {
        owner = _owner;
        maxWeightOfContract = _maxWeightOfContract;
        maxPercentageOfAllContracts = _maxPercentageOfAllContracts;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can access this.");
        _;
    }

    // Function to make a deposit
    function deposit() payable public {
    }

    // function to make a withdrawal
    function withdraw(address _to, uint amount) payable public onlyOwner {
        require(amountAvailableForWithdrawal() >= amount, "Can't withdraw that amount of money");
        payable(_to).transfer(amount);
    }

    // Function used to create an insurance contract
    function createInsuranceContract(
        address _insurable,
        address _expert,
        uint amount,
        uint startDate,
        uint endDate,
        uint amountOfPayments,
        uint contractNumber) public onlyOwner {
        require(getAmountAvailableForInsurance() >= amount, "Pool doesn't have enough resources for that amount");
        InsuranceContract insuranceContract = new InsuranceContract(address(this), _insurable, _expert, startDate, endDate, amount, amountOfPayments, contractNumber);
        totalAmount += amount;
        address insuranceContractAddress = address(insuranceContract);
        insurances[insuranceContractAddress] = insurance(insuranceContract, amount);
        insuranceContractAddresses.push(insuranceContractAddress);
        insuranceExperts[insuranceContractAddress][_expert] = true;
    }

    // Function used to make a compensation
    function compensateDamage(uint amount, address _to) public {
        require(insurances[msg.sender].insuranceContract != InsuranceContract(address(0)), "Sender is not associated with this pool");
        totalAmount -= insurances[msg.sender].amount;
        delete insurances[msg.sender];
        payable(_to).transfer(amount);
    }

    // Function the expert can use to make a payout
    function giveExpertOpinion(bool decision, uint amount, address addressOfContract) public {
        require(insurances[addressOfContract].insuranceContract != InsuranceContract(address(0)), "Sender is not associated with this pool");
        require(insuranceExperts[addressOfContract][msg.sender], "Sender is not an expert for this contract");
        insurances[addressOfContract].insuranceContract.updateExpertOpinion(msg.sender, decision, amount);
    }

    // Gives out the amount available for insurance
    function getAmountAvailableForInsurance() private view returns(uint) {
        uint maxWeightAmount = (address(this).balance * maxWeightOfContract) / 100;
        uint maxPercentageAmount = ((address(this).balance * maxPercentageOfAllContracts) / 100) - totalAmount;
        return maxWeightAmount < maxPercentageAmount ? maxWeightAmount : maxPercentageAmount;
    }

    // Gives out the amount available for withdrawal
    function amountAvailableForWithdrawal() private view returns(uint) {
        uint availableForInsurance = getAmountAvailableForInsurance();
        uint currentBalance = address(this).balance;
        uint maxWithdrawal;

        if (currentBalance >= totalAmount + availableForInsurance) {
            maxWithdrawal = currentBalance - totalAmount - availableForInsurance;
        } else {
            maxWithdrawal = 0;
        }

        return maxWithdrawal;
    }

    // Function to use for local testing and to add a insurance contract to the pool
    function addContractToPool(address _expert, address insuranceContractAddress, uint amount) public onlyOwner {
        insuranceExperts[insuranceContractAddress][_expert] = true;
        insuranceContractAddresses.push(insuranceContractAddress);
        insurances[insuranceContractAddress] = insurance(InsuranceContract(insuranceContractAddress), amount);
        totalAmount += amount;
    }

    // Returns all the contracts that have ever been associated with this contract
    function getInsuranceContractAddresses() public view returns(address[] memory) {
        return insuranceContractAddresses;
    }
}