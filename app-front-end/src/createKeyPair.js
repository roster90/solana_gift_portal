
const {web3} = require('@project-serum/anchor')




const getWalletFromJson =  (keyPair)=>{
    try {
        const arr = Object.values(keyPair._keypair.secretKey)
        const secretKey  = new Uint8Array(arr);
        const wallet = web3.Keypair.fromSecretKey(secretKey);
        console.log(wallet.publicKey.toString());
        return wallet;   
    } catch (error) {
        console.log(error);
        return null;
    }
}
 module.exports ={
    // getWalletFromJsonPairFile, 
    // getAccountFromPrivateKey,
    getWalletFromJson
 }