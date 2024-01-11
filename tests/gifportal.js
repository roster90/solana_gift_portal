const anchor = require("@coral-xyz/anchor");
const { web3 } = require("@project-serum/anchor");
const { Connection, clusterApiUrl, Keypair, LAMPORTS_PER_SOL, StakeProgram, Authorized, Lockup, sendAndConfirmTransaction, PublicKey } = require("@solana/web3.js");

const { getAccountFromKeyFile } = require("./getAcount");


const main = async ()=>{
  console.log('Starting test...');
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);



  const baseAccount = Keypair.generate()
  console.log("baseAccount", baseAccount.publicKey.toString());
  console.log("provider.wallet", provider.wallet.publicKey.toString());

  if(!baseAccount) return;
  const program = anchor.workspace.Gifportal
  
 const tx = await program.rpc.startStuffOff({
  accounts:{
    baseAccount: baseAccount.publicKey,
    user: provider.wallet.publicKey,
    systemProgram: anchor.web3.SystemProgram.programId
  },
  signers: [baseAccount]
 });
 console.log("tx: ",tx );
 let account = await program.account.baseAccount.fetch(baseAccount.publicKey);
 console.log("gifts counts: ", account.totalGifts.toString());
  await program.rpc.addGift(    "testlink",{

  accounts:{
    baseAccount: baseAccount.publicKey,
    user: provider.wallet.publicKey,
  }
 });
 account = await program.account.baseAccount.fetch(baseAccount.publicKey);
 console.log("gifts counts: ", account.totalGifts.toString());
 console.log("gifts List: ", account.giftList);

}

const runMain = async ()=>{
  try {
    await main();
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
}

runMain()