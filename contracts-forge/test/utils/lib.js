const ethers = require('ethers')

/**
  * Convert a base64 string to a `bytes` object
  */
const base64ToBin = (input) => {
  const bin = Uint8Array.from(Buffer.from(input, 'base64').toString('binary'), c => c.charCodeAt(0))
  return ethers.utils.defaultAbiCoder.encode(['bytes'], [bin])
}

/**
  * Shorthand to write directly to stdout
  * @param {string} message
  */
const write = (message) => process.stdout.write(message)

switch (process.argv[2]) {
  case 'base64ToBin':
    write(base64ToBin(process.argv[3]))
    break
  default:
    console.log('Invalid instruction!')
}
