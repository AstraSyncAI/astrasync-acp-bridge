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
