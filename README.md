# Cali-Creds

Using Succinct's SP1 alongside the recently issued California Mobile Driver's License, we can issue on-chain attestations to credential attributes, or "Creds", without revealing unnecessary private information.

## Dependencies

 * [Rust](https://doc.rust-lang.org/cargo/getting-started/installation.html)
 * [SP1](https://github.com/succinctlabs/sp1)
 * [Foundry](https://book.getfoundry.sh/getting-started/installation)
 * [Go](https://go.dev/doc/install)
 * [NodeJS](https://nodejs.org/en/learn/getting-started/how-to-install-nodejs)
 * [MongoDB](https://www.mongodb.com/docs/manual/installation/)
 * [Sqlite3](https://www.sqlite.org/download.html)

## Setup

To produce your own credential for verification with an official Cali-Creds on-chain contract, the easiest flow is as follows:

  ### Set up your opencred server


  Run a mongodb instance to link your opencred server to.

  ```bash
  mongod --port 27017 --dbpath PATH/TO/DBFOLDER
  ```

  Follow OpenCred's setup instructions [here](https://github.com/stateofca/opencred) to create a config using the workflow from configs/combined.example.yaml lines 57-93

  Change the mongodb url on line 10 of your config to point to your mongo instance.

  In order to recieve callbacks, the opencred server must have https functionality enabled. You can do this yourself in production use, but for development a simple solution is running a local https tunnel using [ngrok](https://ngrok.com/) or a similar tool.

  After setting up a tunnel tool, run a local tunnel in a different terminal instance to get the hosted address.
  The default port for the opencred server is 22080
  ```bash
  ngrok http 22080
  ```

  Paste the tunnel address (e.g. https://e932-157-131-203-14.ngrok-free.app) into the URL fields of your combined.yaml at lines 8, 69, and 72.

  Change the callback URL in your combined.yaml at line 96 to match the expected URL of your queue server (see below). Be sure to specify the endpoint in the callback URL ('/callback' by default).

  Run the opencred server in another terminal instance.


  ```bash
  cd opencred
  npm run start
  ```


  ### Run a prover microservice
  (Note: The prover microservice must be run on a server with min 64gb RAM in order to generate proofs in reasonable time.)

  On your proving machine:

  ```bash
  cd prover-microservice
  cp example.env .env
  ```
  PRIVATE KEY is the private key that holds funds to be used to pay gas. Gas cost for issuing a credential is about 450k.
  RPC_URL is a valid rpc url for the chain you want to issue on
  CONTRACT_ADDRESS=the contract to issue credential from, see below for valid contract addresses.

  ```bash
  cargo run --release
  ```


  ### Set up your queue server

  In a separate terminal instance:
  ```bash
  cd queue-server
  ```

  Set up environment variables
  ```bash
  cp example.env .env
  ```
  OPENCRED_SERVER is the http base URL of your opencred server

  OPENCRED_WORKFLOW_ID is the chosen id of the workflow on line 91 of your opencred server's config.yaml

  OPENCRED_USERNAME is the username matching the clientId chosen on line 61 of your opencred server's config.yaml

  OPENCRED_PASSWORD is the password matching the clientSecret chosen on line 62 of your opencred server's config.yaml

  Run the queue server
  ```bash
  go run main.go
  ```


  In a separate terminal instance, add the url of your prover microservice to the queue server:
  ```bash
  sqlite3
  .open data/creds.db
  ```
  ```sql
  INSERT INTO provers (url) VALUES ("YOUR URL HERE");
  ```

  You can check that your url was inserted successfully by running

  ```sql
  SELECT * FROM provers;
  ```

  Then exit your sqlite instance with ^C and you're ready to create your credential.

  ```bash
  curl http://{SERVER_URL}/exchange/{ADDRESS}
  ```

  Where

  SERVER_URL is your queue server

  ADDRESS is the address you want to mint your nft to

  Take the QR field of the server's response and paste it into a browser to generate a QR code to scan with your mDL app, then scan the QR code and accept the credential request, wait a few minutes, and you're done!


## Official Contracts
| Chain | Type | Address |
|-------|------|---------|
|OP Sepolia|City|0x3db47Cf91223B696b5BDd20c273172aDF39bae1f|
|Polygon Amoy|City|0xf35084f1E01D4B43b1c187b4fB8AB49Aa7E22206|
|Polygon Amoy|Over 21|0x0AfD2096AE402bADFA603d84442cBfce1C945b35|

Contracts use different circuits based on cred type, and are currently being updated constantly. Check out other branches of the repo [here](https://github.com/pjol/Cali-Creds/branches) to find the credential you need.
