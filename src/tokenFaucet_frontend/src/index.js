import { tokenFaucet_backend } from "../../declarations/tokenFaucet_backend";
import {Principal} from "@dfinity/principal";


document.querySelector("form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const button = e.target.querySelector("button");

        const loader = document.querySelector('.loader-container');
        loader.style.display = 'block';
        try{


         const principalId = document.getElementById("principalid").value.toString();

          const realId = Principal.fromText(principalId);

          const claimResult = await tokenFaucet_backend.claimTokens(realId);


          loader.style.display = 'none';

          document.getElementById("error-container").style.display = 'block';

          if(claimResult.err){
            document.getElementById("responseId").innerText = claimResult.err;

          }else{
            document.getElementById("responseId").innerText = claimResult.ok;


          }

        }catch(error){
          loader.style.display = 'none';
          document.getElementById("responseId").innerText = error;
        }
});
