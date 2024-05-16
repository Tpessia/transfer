const http = require('http');

const timeout = +process.argv[2] || 10000;

console.log(`starting killer (timeout=${timeout})`);

http.get('http://localhost:3000/kill', response => {
  let data = '';
  response.on('data', chunk => data += chunk);
  response.on('end', () => {
    console.log(data, timeout);
    let count = 0;
    setInterval(() => {
      console.log(`killing (${++count}/${timeout/1000})...`);
      if (count >= timeout/1000) {
        console.log('killer killed!');
        process.exit();
      }
    }, 1000);
  });
}).on('error', error => console.error(`Error: ${error.message}`));