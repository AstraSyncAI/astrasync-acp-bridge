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
