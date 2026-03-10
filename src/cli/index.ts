#!/usr/bin/env node

import { program } from 'commander'
import { loadEnv } from './utils/env'
import { router } from './router'

loadEnv()

program
  .name('orbit-actions')
  .description('CLI for Orbit chain upgrade actions')
  .argument('[path]', 'Path to browse or command to run')
  .argument('[args...]', 'Additional arguments')
  .action(async (pathArg?: string, args?: string[]) => {
    await router(pathArg, args)
  })

program.parse()
