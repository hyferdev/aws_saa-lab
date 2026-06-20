module.exports = {
  apps: [
    {
      name: 'frontdesk',
      script: 'server.js',
      interpreter: 'node',
      env: { PORT: '3000', NODE_ENV: 'production' },
      restart_delay: 3000,
      max_restarts: 10,
    },
    {
      name: 'frontdesk-mcp',
      script: 'mcp-server.js',
      interpreter: 'node',
      env: { MCP_PORT: '3001', NODE_ENV: 'production' },
      restart_delay: 3000,
      max_restarts: 10,
    },
  ],
};
