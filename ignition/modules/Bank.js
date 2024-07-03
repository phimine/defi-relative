const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("BankModule", (m) => {
    const bankContract = m.contract("Bank", []);
    return { bankContract };
});
