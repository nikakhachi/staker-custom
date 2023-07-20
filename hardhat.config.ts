import "@nomicfoundation/hardhat-foundry";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-verify";
import "dotenv/config";

const config = {
  solidity: "0.8.19",
  networks: {
    mumbai: {
      chainId: 80001,
      url: process.env.MUMBAI_RPC_URL,
      accounts: [process.env.PRIVATE_KEY || ""],
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
    },
  },
};

export default config;
