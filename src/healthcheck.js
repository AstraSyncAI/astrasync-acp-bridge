import { ACPBridge } from './bridge.js';
import { validateConfig } from './config.js';
import { parseACPAgent } from './acp-parser.js';
import chalk from 'chalk';

async function checkHealth() {
  console.log(chalk.blue('🏥 AstraSync ACP Bridge Health Check\n'));
  
  try {
    const config = validateConfig();
    console.log(chalk.green('✅ Configuration loaded'));
    console.log(`   API URL: ${config.apiUrl}`);
    console.log(`   Email: ${config.developerEmail}\n`);
    
    // Test API connectivity
    const response = await fetch(config.apiUrl);
    if (response.ok) {
      console.log(chalk.green('✅ API is reachable'));
    } else {
      console.log(chalk.yellow('⚠️  API returned status:'), response.status);
    }
    
    // Test ACP parsing
    const testAgent = {
      id: 'test-agent',
      name: 'Test ACP Agent',
      capabilities: ['test'],
      skills: []
    };
    
    const parsed = await parseACPAgent(testAgent);
    console.log(chalk.green('✅ ACP parser working'));
    
    console.log(chalk.green('\n✨ All systems operational!'));
    
  } catch (error) {
    console.error(chalk.red('❌ Health check failed:'), error.message);
    process.exit(1);
  }
}

checkHealth();
