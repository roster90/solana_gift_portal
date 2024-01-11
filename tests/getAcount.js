const { Connection, clusterApiUrl, Keypair, LAMPORTS_PER_SOL, StakeProgram, Authorized, Lockup, sendAndConfirmTransaction, PublicKey } = require("@solana/web3.js");

const bs58 = require('bs58')
const fs = require('fs');
const util = require('util');
const readFile = util.promisify(fs.readFile);


const getAccountFromKeyFile = async (path_file_key)=>{
    try {

        const data =  await readFile(path_file_key,'utf-8');
      
        const buf = bs58.decode(data)

        const wallet = Keypair.fromSecretKey(buf, {skipValidation: true});

        return wallet
    } catch (error) {
        console.log(error);
        return null;
    }
}

module.exports = {
    getAccountFromKeyFile
}