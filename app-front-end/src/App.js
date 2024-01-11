


import twitterLogo from "./assets/twitter-logo.svg";
import "./App.css";
import { useEffect, useState } from "react";
import idl from './idl/gifportal.json'
import {Connection, Keypair, PublicKey, clusterApiUrl} from '@solana/web3.js';
import {Program, AnchorProvider, web3, utils, BN} from '@project-serum/anchor';
import {Buffer} from 'buffer';
import { getWalletFromJson } from "./createKeyPair";
import kp from './keypair.json'
window.Buffer = Buffer;

// Constants
const TWITTER_HANDLE = "_buildspace";
const TWITTER_LINK = `https://twitter.com/${TWITTER_HANDLE}`;

const TEST_GIFS = [
  "https://i.ibb.co/3B3r3Kg/VERVE.jpg",
  "https://i.ibb.co/mGdVJcP/METO.jpg",
  "https://i.ibb.co/NmKPt6s/GQ.jpg"
]
const baseAccount = getWalletFromJson(kp)

const programID = new PublicKey(idl.metadata.address)
const network = clusterApiUrl('devnet');
const opts = {
  preflightCommitment: "processed",
  commitment: "processed",
}
const {SystemProgram} = web3;




const App = () => {

  const [walletAddress, setWalletAddress] = useState(null);
  const [inputValue, setInputValue] = useState("");
  const [giftsList, setGiftsList] = useState(null);

  const checkIfWalletIsConnected = async () => {
    try {
      const { solana } = window;

      if (solana.isPhantom) {
        const response = await solana.connect({ onlyIfTrusted: true });

        console.log(
          "Connected with public key: ",
          response.publicKey.toString()
        );
        setWalletAddress(response.publicKey.toString());
      } else {
        alert("Sonala wallet is not found!");
      }
    } catch (error) {
      console.log(error);
    }
  };
  const connectWallet = async () => {
    const { solana } = window;
    if (solana) {
      const response = await solana.connect();
      setWalletAddress(response.publicKey.toString());
      console.log("Connected with public key: ", response.publicKey.toString());
    }
  };
  const disconnectWallet = async () => {
    const { solana } = window;
    if (solana) {
      await solana.disconnect()
      setWalletAddress(null);
      console.log("disconnect");
    }
  };

  const onInputChange = (event)=>{
    event.preventDefault();
    setInputValue(event.target.value)
  }
  const sendGif = async ()=>{
    if(inputValue.length >0){
      addGift(inputValue)
      setInputValue("");
    }
  }
  useEffect(()=>{
  

    if(walletAddress){
      // createAccount();
      getGistList()
    }
  },[walletAddress])

  const getGistList = async ()=>{
    try {
      const provider = getProvider();
      const program = new Program(idl, programID, provider);
      const  account = await program.account.baseAccount.fetch(baseAccount.publicKey);
      console.log("gifts counts: ", account.totalGifts.toString());
      console.log("gifts List: ", account.giftList);
      setGiftsList(account.giftList)
    } catch (error) {
      setGiftsList(null)
      console.log(error);
    }
  }

  const addGift = async (giftLink) =>{
    try {
      const provider = getProvider();
      const program = new Program(idl, programID, provider);
      await program.rpc.addGift( giftLink.toString(),{
        accounts:{
          baseAccount: baseAccount.publicKey,
          user: provider.wallet.publicKey,
        }
       });

     await getGistList();
    } catch (error) {
      console.log(error);
    }
  }
  const createGiftAccount = async () =>{
    try {
      const provider = getProvider();
      const program = new Program(idl, programID, provider);
      await program.rpc.startStuffOff({
        accounts:{
          baseAccount: baseAccount.publicKey,
          user: provider.wallet.publicKey,
          systemProgram: SystemProgram.programId
        },
        signers: [baseAccount]
       });
       console.log("create  Base Account: ", baseAccount.publicKey.toString());
       await getGistList();
    } catch (error) {
      console.log(error);
    }
  }
  

  const getProvider = () =>{
    const connection = new Connection(network, opts.preflightCommitment);
    const provider = new AnchorProvider(connection, window.solana, opts.preflightCommitment);
    return provider
  }


  useEffect(() => {
    const onLoad = async () => {
      await checkIfWalletIsConnected();

    };

    window.addEventListener("load", onLoad);
    return () => window.removeEventListener("load", onLoad);
  }, []);

  const renderNotConnectedContainer = ()=>(
   
     <button  className="cta-button connect-wallet-button" onClick={connectWallet}>Connect Wallet</button>
  )
  
  const renderConnectedContainer = ()=>{
    if(giftsList === null){
        return <div className="connected-container">
            <button type="submit" className="cta-button submit-gif-button" onClick={createGiftAccount}>
              Do One Time Initialization for GIF Program Account 
            </button>
        </div>
    }
    return (
      <div  className="connected-container">
        <form onSubmit={(event)=>{
          event.preventDefault()
          sendGif();
        }}>
          <input type ="text" placeholder="Enter gif link" value={inputValue} onChange={onInputChange}/> 
          <button type="submit" className="cta-button submit-gif-button">Submit</button>
  
        </form>
          <div className="gif-grid">
              { giftsList.map(( item, index)=>(
                <div  className="gif-item" key={index}>
                  <img src={item.giftLink} alt={item.giftLink} className="gif"/>
  
                </div>
              ))
  
              }
  
          </div>
      
        
  
      </div>
    
    )
  }

  return (
    <div className="App">
      <div className={walletAddress? 'authed-container': "container"}>
        <div className="header-container">
          <p className="header">🖼 GIF Portal</p>
          <p className="sub-text">
            View your GIF collection in the metaverse ✨
          </p>
          { !walletAddress ? renderNotConnectedContainer(): renderConnectedContainer()}
        </div>
        <div className="footer-container">
          <img alt="Twitter Logo" className="twitter-logo" src={twitterLogo} />
          <a
            className="footer-text"
            href={TWITTER_LINK}
            target="_blank"
            rel="noreferrer"
          >{`built on @${TWITTER_HANDLE}`}</a>
        </div>
      </div>
    </div>
  );
};

export default App;
