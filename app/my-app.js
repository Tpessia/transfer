const fs = require('fs');
const os = require('os');
const http = require('http');

console.log('DUMP:', os.homedir(), process.env.USER, __dirname, process.cwd(), process.argv);

// CONFIG

const state = {
  start: new Date(),
  file: `${__dirname}/output.txt`,
  killTimeout: +process.argv[2] || 5000,
  killStart: undefined,
  killEnd: undefined,
};

fs.writeFileSync(state.file, 'running');

// SERVER

const server = http.createServer((req, res) => {
  const isKillCmd = req.url === '/kill';

  if (isKillCmd) {
    exitHandler({ final: false }, null);
    res.writeHead(200).end('killing...');
  } else {
    res.writeHead(200).end('waiting for /kill');
  }
});

server.listen(3000, async () => {
  console.log(`listening on http://localhost:3000/ (timeout=${state.killTimeout}, file=${state.file})`);

  let count = 0;
  while (true) {
    await new Promise(res => setTimeout(res, 1000));
    console.log(`running: ${++count}`);
  }
});

// EXIT

function exitHandler(options, exitCode) {
  console.log('exit', options.final, exitCode);

  if (options.final) {
    state.killEnd = new Date();
    const stateStr = JSON.stringify(state);
    fs.writeFileSync(state.file, stateStr);
    console.log(`dead!\n${stateStr}`);
  } else {
    console.log(`killing in ${state.killTimeout}ms...`)
    state.killStart = new Date();
    setTimeout(() => process.exit(), state.killTimeout);
  }
}

process.on('exit', exitHandler.bind(null, { final: true }));

process.on('SIGINT', exitHandler.bind(null, { final: false }));
process.on('SIGTERM', exitHandler.bind(null, { final: false }));

process.on('uncaughtException', exitHandler.bind(null, { final: false }));