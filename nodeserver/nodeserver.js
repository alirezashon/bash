const http = require('http')
const net = require('net')
const WebSocket = require('ws')
 

const server = http.createServer((req, res) => {
  console.log('\n====================')
  console.log(req.method, req.url)
  console.log('Headers:', req.headers)

 
  if (req.url === '/') {
    res.writeHead(302, {
      Location: '/api'
    })
    res.end()
    return
  }
 
  if (req.url === '/api') {
    let rawData = Buffer.alloc(0)

    req.on('data', chunk => {
      rawData = Buffer.concat([rawData, chunk])
    })

    req.on('end', () => {
      console.log('BODY:', rawData.toString())

      res.writeHead(200, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({
        ok: true,
        message: 'You reached the final destination 🎯',
        bodyLength: rawData.length,
        body: rawData.toString()
      }, null, 2))
    })
    return
  }

  res.writeHead(404)
  res.end('Not Found')
})

server.listen(3000, () => {
  console.log('🚀 Listening on http://localhost:3000')
})
/* ================= WebSocket ================= */
const wss = new WebSocket.Server({ port: 3001 })

wss.on('connection', ws => {
  console.log('[WS] client connected')

  ws.on('message', msg => {
    console.log('[WS] received:', msg.toString())
    ws.send(`echo: ${msg}`)
  })

  ws.send('welcome to ws server')
})

console.log('🔌 WebSocket → ws://localhost:3001')

/* ================= TCP ================= */
const tcpServer = net.createServer(socket => {
  console.log('[TCP] client connected')

  socket.write('salam az TCP node\n')

  socket.on('data', data => {
    console.log('[TCP] received:', data.toString())
    socket.write(`echo: ${data}`)
  })
})

tcpServer.listen(9000, () =>
  console.log('📡 TCP server → localhost:9000')
)
