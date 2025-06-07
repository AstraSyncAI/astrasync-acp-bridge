#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import fs from 'fs/promises';
import path from 'path';
import { ACPBridge } from './bridge.js';
import { validateConfig } from './config.js';

const program = new Command();

program
  .name('astrasync-acp')
  .description('Register IBM ACP agents with AstraSync')
  .version('0.1.0');

program
  .command('register <source>')
  .description('Register an ACP agent from JSON file or manifest')
  .option('-o, --output <file>', 'Output file for registration result')
  .option('-e, --email <email>', 'Developer email (overrides env)')
  .action(async (source, options) => {
    const spinner = ora('Initializing ACP Bridge...').start();
    
    try {
      // Validate configuration
      const config = validateConfig();
      
      // Create bridge instance
      const bridge = new ACPBridge(
        config.apiUrl,
        options.email || config.developerEmail
      );
      
      // Read agent data
      spinner.text = 'Reading ACP agent data...';
      let agentData;
      
      if (source.startsWith('{')) {
        // Direct JSON input
        agentData = source;
      } else {
        // File path
        const content = await fs.readFile(source, 'utf-8');
        agentData = content;
      }
      
      // Register agent
      spinner.text = 'Registering with AstraSync...';
      const result = await bridge.registerACPAgent(agentData);
      
      spinner.succeed(chalk.green('✅ Agent registered successfully!'));
      
      // Display results
      console.log('\n' + chalk.blue('📋 Registration Summary:'));
      console.log(chalk.gray('─'.repeat(50)));
      console.log(chalk.white('Agent ID:'), chalk.yellow(result.astraSync.agentId));
      console.log(chalk.white('Trust Score:'), chalk.green(result.astraSync.trustScore));
      console.log(chalk.white('Name:'), result.original.name);
      console.log(chalk.white('Status:'), chalk.green(result.astraSync.status));
      console.log(chalk.gray('─'.repeat(50)));
      
      // Save results
      const outputFile = options.output || 
        `${result.original.name.toLowerCase().replace(/\s+/g, '-')}-${result.astraSync.agentId}.json`;
      
      await fs.writeFile(
        outputFile,
        JSON.stringify(result, null, 2)
      );
      
      console.log('\n' + chalk.green('💾 Results saved to:'), chalk.cyan(outputFile));
      console.log('\n' + chalk.yellow('🚀 Next steps:'));
      console.log('   1. Share your agent ID:', chalk.cyan(result.astraSync.agentId));
      console.log('   2. View on web:', chalk.cyan(`https://astrasync.ai/agent/${result.astraSync.agentId}`));
      console.log('   3. When ready, upgrade at:', chalk.cyan('https://astrasync.ai/signup'));
      
    } catch (error) {
      spinner.fail(chalk.red('Registration failed'));
      console.error(chalk.red('\n❌ Error:'), error.message);
      process.exit(1);
    }
  });

program
  .command('verify <agentId>')
  .description('Verify an agent registration')
  .action(async (agentId) => {
    const spinner = ora('Verifying agent...').start();
    
    try {
      const config = validateConfig();
      const bridge = new ACPBridge(config.apiUrl);
      
      const result = await bridge.verifyAgent(agentId);
      
      spinner.succeed(chalk.green('✅ Agent verified!'));
      console.log('\n' + chalk.blue('Agent Details:'));
      console.log(result);
      
    } catch (error) {
      spinner.fail(chalk.red('Verification failed'));
      console.error(chalk.red('\n❌ Error:'), error.message);
      process.exit(1);
    }
  });

program.parse();
