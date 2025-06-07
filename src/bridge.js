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
