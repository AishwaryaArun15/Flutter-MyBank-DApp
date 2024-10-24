module.exports = {
  networks: {
    development: {
      host: "10.0.2.2",
      port: "7545",
      network_id: "*" 
    }
  },

  contracts_directory: "./contracts",
  compilers: {
    solc: {
      version: "0.8.19",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },

  db: {
    enabled: false
  }
}