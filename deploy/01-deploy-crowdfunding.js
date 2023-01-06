const {network, ethers} = require("hardhat")
const {verify} = require("../utils/verify")
require("dotenv").config()


module.exports = async function({deployments, getNamedAccounts}){
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()
    const chainId = network.config.chainId

    const _deadline = 3600
    const _targetAmount = ethers.utils.parseEther("5")

    log("Deploying............................")

    const args = [_deadline,_targetAmount]

    const crowdFunding = await deploy("CrowdFunding",{
        from: deployer,
        log: true,
        args: args,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    log("deployed.........................")

    

    if(chainId != 31337 && process.env.ETHERSCAN_API_KEY){

        log("Verifying the contract.................")
        await verify(crowdFunding.address,args)

        log(`contract verified with contract address ${crowdFunding.address}`)
    }

    

}

module.exports.tags = ["all","main"]