#!/bin/bash

echo "🚀 Creating all AstraSync ACP Bridge files..."

# Create src directory
mkdir -p src

# Create src/config.js
cat > src/config.js << 'EOF'
// Configuration with correct precedence
export const config = {
  getApiUrl: () => process.env.ASTRASYNC_API_URL || 'https://astrasync.ai/api',
  getDeveloperEmail: () => process.env.DEVELOPER_EMAIL || 'developer@example.com',
  isDemoMode: () => process.env.DEMO_MODE === 'true' || false
};

// Validate configuration
export function validateConfig() {
  const email = config.getDeveloperEmail();
  
  if (!email || email === 'developer@example.com') {
    console.warn('⚠️  Using default email. Set DEVELOPER_EMAIL environment variable.');
  }
  
  return {
    apiUrl: config.getApiUrl(),
    developerEmail: email,
    isDemoMode: config.isDemoMode()
  };
}
EOF

# Create src/acp-parser.js
cat > src/acp-parser.js << 'EOF'
// Parse ACP agent manifest/metadata
export async function parseACPAgent(agentData) {
  console.log('🔍 Parsing ACP agent data...');
  
  // ACP agents might come in different formats
  // Let's handle the most common cases
  
  if (typeof agentData === 'string') {
    try {
      agentData = JSON.parse(agentData);
    } catch (e) {
      throw new Error('Invalid ACP agent data: Not valid JSON');
    }
  }
  
  // Extract core fields based on ACP spec
  const parsed = {
    id: agentData.id || agentData.agentId || 'unknown',
    name: agentData.name || agentData.agentName || 'Unnamed ACP Agent',
    description: agentData.description || agentData.agentDescription || 'An ACP-compliant agent',
    version: agentData.version || '1.0.0',
    capabilities: extractCapabilities(agentData),
    authentication: agentData.authentication || {},
    skills: agentData.skills || [],
    metadata: {
      source: 'acp',
      originalId: agentData.id || agentData.agentId,
      framework: agentData.framework || 'beeai',
      endpoint: agentData.endpoint || agentData.url || null
    }
  };
  
  console.log('✅ Successfully parsed ACP agent:', parsed.name);
  return parsed;
}

function extractCapabilities(agentData) {
  // ACP capabilities might be in different places
  if (Array.isArray(agentData.capabilities)) {
    return agentData.capabilities;
  }
  
  if (agentData.capability) {
    return [agentData.capability];
  }
  
  // Extract from skills if no explicit capabilities
  if (Array.isArray(agentData.skills)) {
    return agentData.skills.map(skill => skill.id || skill.name);
  }
  
  return ['acp-compliant'];
}
EOF

# Create src/bridge.js
cat > src/bridge.js << 'EOF'
import fetch from 'node-fetch';
import { config } from './config.js';
import { parseACPAgent } from './acp-parser.js';

export class ACPBridge {
  constructor(apiUrl = null, developerEmail = null) {
    // Correct precedence: parameter → env → default
    this.apiUrl = apiUrl || config.getApiUrl();
    this.developerEmail = developerEmail || config.getDeveloperEmail();
    console.log(`🔗 ACP Bridge initialized with API: ${this.apiUrl}`);
  }
  
  async registerACPAgent(agentData) {
    try {
      // Parse ACP agent data
      const parsedAgent = await parseACPAgent(agentData);
      
      // Map to AstraSync format (lessons from yesterday!)
      const payload = {
        email: this.developerEmail,  // Email at root level!
        agent: {  // Agent data nested!
          name: parsedAgent.name,
          description: parsedAgent.description,
          owner: this.developerEmail,  // Use email as owner
          capabilities: parsedAgent.capabilities,
          version: parsedAgent.version,
          agentType: 'acp',
          acpId: parsedAgent.id,
          acpMetadata: parsedAgent.metadata,
          skills: parsedAgent.skills.length,
          authentication: parsedAgent.authentication,
          importedAt: new Date().toISOString()
        }
      };
      
      console.log('📤 Registering with AstraSync...');
      
      // Make the API call (correct endpoint!)
      const response = await fetch(`${this.apiUrl}/v1/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-source': 'acp-bridge'
        },
        body: JSON.stringify(payload)
      });
      
      const result = await response.json();
      
      if (!response.ok) {
        throw new Error(result.error || `Registration failed: ${response.status}`);
      }
      
      // Generate enhanced response with agent.json format
      const enhancedResult = {
        astraSync: {
          agentId: result.agentId,
          status: result.status || 'registered',
          trustScore: this.calculateTrustScore(parsedAgent),
          blockchain: {
            status: 'pending',
            message: 'Blockchain registration queued'
          },
          registeredAt: new Date().toISOString()
        },
        original: parsedAgent,
        registration: {
          email: this.developerEmail,
          source: 'acp-bridge',
          apiVersion: 'v1'
        }
      };
      
      return enhancedResult;
      
    } catch (error) {
      console.error('❌ Registration failed:', error.message);
      throw error;
    }
  }
  
  calculateTrustScore(agentData) {
    // Simple trust score calculation for preview
    let score = 70; // Base score
    
    if (agentData.authentication?.schemes?.length > 0) score += 10;
    if (agentData.skills?.length > 0) score += Math.min(agentData.skills.length * 2, 10);
    if (agentData.description?.length > 50) score += 5;
    if (agentData.version) score += 5;
    
    return `TEMP-${Math.min(score, 100)}%`;
  }
  
  async verifyAgent(agentId) {
    try {
      const response = await fetch(`${this.apiUrl}/v1/verify/${agentId}`, {
        headers: { 'x-source': 'acp-bridge' }
      });
      
      if (!response.ok) {
        throw new Error(`Verification failed: ${response.status}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error('❌ Verification failed:', error.message);
      throw error;
    }
  }
}
EOF

# Create src/cli.js
cat > src/cli.js << 'EOF'
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
EOF

# Create src/healthcheck.js
cat > src/healthcheck.js << 'EOF'
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
EOF

# Create test-agent.json
cat > test-agent.json << 'EOF'
{
  "id": "beeai-test-agent",
  "name": "BeeAI Test Agent",
  "description": "A test agent from IBM's BeeAI platform demonstrating ACP compliance",
  "version": "1.0.0",
  "capabilities": [
    "task-execution",
    "peer-to-peer",
    "async-messaging"
  ],
  "skills": [
    {
      "id": "data-analysis",
      "name": "Data Analysis",
      "description": "Analyzes structured and unstructured data"
    },
    {
      "id": "report-generation",
      "name": "Report Generation",
      "description": "Creates comprehensive reports"
    }
  ],
  "authentication": {
    "schemes": ["oauth2.1"],
    "endpoint": "https://auth.beeai.dev/token"
  },
  "endpoint": "https://agents.beeai.dev/test-agent"
}
EOF

# Make CLI executable
chmod +x src/cli.js

echo "✅ All files created successfully!"
echo ""
echo "Now run:"
echo "  node src/healthcheck.js"
echo "  node src/cli.js register test-agent.json"