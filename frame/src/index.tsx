import { serve } from '@hono/node-server'
import { serveStatic } from '@hono/node-server/serve-static'
import { Button, FrameContext, Frog, TextInput } from 'frog'
import { devtools } from 'frog/dev'
import { env } from 'node:process'
import { isAddress } from 'web3-validator'
import 'dotenv/config'
// import { neynar } from 'frog/hubs'

const PROVER_SERVER_URL = env.PROVER_SERVER || "localhost:8080"

const EXAMPLE_QR = 'data:image/png;base64,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'

export const app = new Frog({
  // Supply a Hub to enable frame verification.
  // hub: neynar({ apiKey: 'NEYNAR_FROG_FM' })
  title: 'California mDL City Cred Issuer'
})

const ErrorFrame = (c: FrameContext, message: string) => {
  return c.res({
    image: (
      <div
        style={{
          alignItems: 'center',
          background: '#ffffff',
          backgroundSize: '100% 100%',
          display: 'flex',
          flexDirection: 'column',
          flexWrap: 'nowrap',
          height: '100%',
          justifyContent: 'center',
          textAlign: 'center',
          width: '100%',
        }}
      >
        <div
          style={{
            color: '#eb6c6c',
            fontSize: 60,
            fontStyle: 'normal',
            letterSpacing: '-0.025em',
            lineHeight: 1.4,
            marginTop: 30,
            padding: '0 120px',
            whiteSpace: 'pre-wrap',
            display: 'flex'
          }}
        >
          {message}
        </div>
      </div>
    ),
    intents: [
      <Button.Reset>Reset</Button.Reset>
    ],
  })
}

app.use('/*', serveStatic({ root: './public' }))

app.frame('/', (c) => {
  return c.res({
    action: "/start",
    image: (
      <div
        style={{
          alignItems: 'center',
          background: '#eb6c6c',
          backgroundSize: '100% 100%',
          display: 'flex',
          flexDirection: 'column',
          flexWrap: 'nowrap',
          height: '600px',
          justifyContent: 'center',
          textAlign: 'center',
          width: '100%',
        }}
      >
        <div
          style={{
            color: '#ffffff',
            fontSize: 50,
            fontStyle: 'normal',
            fontWeight: '900',
            letterSpacing: '-0.025em',
            lineHeight: 1.4,
            marginTop: 30,
            padding: '0 120px',
            whiteSpace: 'pre-wrap',
            display: 'flex',
          }}
        >
          Welcome to the mDL City Cred Portal!
        </div>
        <div
          style={{
            color: '#ffffff',
            fontSize: 30,
            fontStyle: 'normal',
            letterSpacing: '-0.025em',
            lineHeight: 1.4,
            marginTop: 30,
            padding: '0 120px',
            whiteSpace: 'pre-wrap',
            display: 'flex',
          }}
        >
          Enter the address to issue your credential to, or leave blank to continue with your default Farcaster address.
        </div>

      </div>
    ),
    intents: [
      <TextInput placeholder="Enter address..."></TextInput>,
      <Button>Next</Button>,
    ],
  })
})

app.frame('/start', async (c) => {
  const { buttonValue, inputText, status, frameData } = c

  const address = inputText || frameData?.address || "no address"

  if(!isAddress(address)) {
    return ErrorFrame(c, "Invalid address, please try again.")
  }

  const url = PROVER_SERVER_URL + "/exchange/" + address

  console.log(url)
  let res = await fetch(url).catch(console.error)
  let exchange = await res?.json() || {QR: EXAMPLE_QR, OID4VP: "test link"}

  const {OID4VP, QR} = exchange;

  console.log

  return c.res({
    image: (
      <div
        style={{
          alignItems: 'center',
          background: '#ffffff',
          backgroundSize: '100% 100%',
          display: 'flex',
          flexDirection: 'column',
          flexWrap: 'nowrap',
          height: '100%',
          justifyContent: 'center',
          textAlign: 'center',
          width: '100%',
        }}
      >
        <div
          style={{
            color: '#eb6c6c',
            fontSize: 60,
            fontStyle: 'normal',
            letterSpacing: '-0.025em',
            lineHeight: 1.4,
            marginTop: 30,
            padding: '0 120px',
            whiteSpace: 'pre-wrap',
            display: 'flex',
            height: "300px",
          }}
        >
          How would you like to link your mDL?
        </div>
      </div>
    ),
    intents: [
      <Button.Link href={OID4VP}>Redirect to mDL</Button.Link>,
      <Button action="/qr" value={QR}>Generate QR</Button>,
    ],
  })
})

app.frame('/qr', async (c) => {
  const { buttonValue, inputText, status, frameData } = c

  const qr = buttonValue || "error"

  return c.res({
    image: qr,
    imageAspectRatio: '1:1',
    intents: [
        <Button.Reset>Reset</Button.Reset>
    ],
  })
})





// app.frame('/exchange', (c) => {
//   return c.res({
//     image: (
//       <div
//         style={{
//           alignItems: 'center',
//           background: '#eb6c6c',
//           backgroundSize: '100% 100%',
//           display: 'flex',
//           flexDirection: 'column',
//           flexWrap: 'nowrap',
//           height: '100%',
//           justifyContent: 'center',
//           textAlign: 'center',
//           width: '100%',
//         }}
//       >
//         <div
//           style={{
//             color: '#ffffff',
//             fontSize: 60,
//             fontStyle: 'normal',
//             letterSpacing: '-0.025em',
//             lineHeight: 1.4,
//             marginTop: 30,
//             padding: '0 120px',
//             whiteSpace: 'pre-wrap',
//           }}
//         >
//         </div>
//       </div>
//     ),
//     intents: [
//       <Button value="tes"></Button>
//     ]
//   })
// })

const port = 3000
console.log(`Server is running on port ${port}`)

devtools(app, { serveStatic })

serve({
  fetch: app.fetch,
  port,
})
