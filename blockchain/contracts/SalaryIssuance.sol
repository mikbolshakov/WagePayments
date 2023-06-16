// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SalaryIssuance is AccessControl {
    ERC20 public salaryToken;
    struct Employee {
        address wallet;
        uint256 salary;
        uint256 bonus;
        uint256 penalty;
    }

    mapping(uint256 => Employee) public employees;
    uint256 private numberOfEmployees;

    bytes32 public constant SALARY_ROLE = keccak256("SALARY_ROLE");

    event AddEmployee(
        uint256 employeeNumber,
        address employeeWallet,
        uint256 employeeSalary
    );

    constructor(address _salaryToken, address _defaultAdmin) {
        salaryToken = ERC20(_salaryToken);
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    function addEmployee(
        address _wallet,
        uint256 _salary
    ) external onlyRole(SALARY_ROLE) {
        for (uint256 i = 1; i <= numberOfEmployees; i++) {
            if (_wallet == employees[i].wallet) {
                revert("The employee is already registered");
            }
        }
        numberOfEmployees++;
        employees[numberOfEmployees].wallet = _wallet;
        employees[numberOfEmployees].salary = _salary;

        emit AddEmployee(numberOfEmployees, _wallet, _salary);
    }

    function deleteEmployee(
        uint256 _employeeNumber
    ) external onlyRole(SALARY_ROLE) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        employees[_employeeNumber].wallet = address(0);
        employees[_employeeNumber].salary = 0;
        employees[_employeeNumber].bonus = 0;
        employees[_employeeNumber].penalty = 0;
    }

    function checkEmployeeNumber(
        address _employeeWallet
    ) external view returns (uint256 employeeNumber) {
        for (uint256 i = 1; i <= numberOfEmployees; i++) {
            if (employees[i].wallet == _employeeWallet) {
                return i;
            }
        }
    }

    function checkEmployeeWallet(
        uint256 _employeeNumber
    ) external view returns (address employeeWallet) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        return employees[_employeeNumber].wallet;
    }

    function checkEmployeeSalary(
        uint256 _employeeNumber
    ) external view returns (uint256 employeeSalary) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        return employees[_employeeNumber].salary;
    }

    function checkEmployeeBonus(
        uint256 _employeeNumber
    ) external view returns (uint256 employeeBonus) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        return employees[_employeeNumber].bonus;
    }

    function checkEmployeePenalty(
        uint256 _employeeNumber
    ) external view returns (uint256 employeePenalty) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        return employees[_employeeNumber].penalty;
    }

    function setEmployeeSalary(
        uint256 _employeeNumber,
        uint256 _salary
    ) external onlyRole(SALARY_ROLE) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        Employee memory employee = employees[_employeeNumber];
        if (
            employee.penalty > employee.bonus &&
            _salary < employee.penalty - employee.bonus
        ) {
            revert("Unprofitable employee");
        }

        employees[_employeeNumber].salary = _salary;
    }

    function setEmployeeBonus(
        uint256 _employeeNumber,
        uint256 _bonus
    ) external onlyRole(SALARY_ROLE) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        employees[_employeeNumber].bonus = _bonus;
    }

    function setEmployeePenalty(
        uint256 _employeeNumber,
        uint256 _penalty
    ) external onlyRole(SALARY_ROLE) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        uint256 checkProfit = employees[_employeeNumber].penalty + _penalty;
        require(
            employees[_employeeNumber].salary +
                employees[_employeeNumber].bonus >
                checkProfit,
            "Unprofitable employee"
        );
        employees[_employeeNumber].penalty = _penalty;
    }

    function calculatePayoutAmount(
        uint256 _employeeNumber
    ) public view returns (uint256) {
        require(_employeeNumber <= numberOfEmployees, "Employee number does not exist");
        Employee memory employee = employees[_employeeNumber];
        return employee.salary + employee.bonus - employee.penalty;
    }

    function paySalary() external payable onlyRole(SALARY_ROLE) {
        for (uint256 i = 1; i <= numberOfEmployees; i++) {
            uint256 payoutAmount = calculatePayoutAmount(i);
            address employeeWallet = employees[i].wallet;
            require(
                payoutAmount <= salaryToken.balanceOf(address(this)),
                "Contract doesn't have enough balance to pay the salary"
            );
            if (employeeWallet != address(0)) {
                employees[i].bonus = 0;
                employees[i].penalty = 0;
                salaryToken.transfer(employeeWallet, payoutAmount);
            }
        }
    }
}