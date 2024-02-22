import * as fs from 'fs'
fs.rmdirSync('build', { recursive: true })
fs.renameSync('package.json.bak', 'package.json')
fs.renameSync('hardhat.config.ts.bak', 'hardhat.config.ts')
fs.rmSync('hardhat.config.js')
