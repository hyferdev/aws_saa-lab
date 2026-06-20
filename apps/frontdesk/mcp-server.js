import express from 'express';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { z } from 'zod';
import { createVisit, checkoutVisit, getVisit, getTodaySummary } from './db.js';

const PORT = process.env.MCP_PORT || 3001;

// New server+transport pair per request — stateless HTTP mode.
function buildServer() {
  const server = new McpServer({ name: 'frontdesk', version: '1.0.0' });

  // Returns visit ID and timestamp only — no PII in tool response.
  server.tool(
    'checkin_visitor',
    'Check in a visitor. Returns visit ID and check-in time.',
    {
      visitor_name: z.string().describe('Full name of the visitor'),
      host_name: z.string().describe('Name of the employee being visited'),
      company: z.string().optional(),
      purpose: z.string().optional(),
    },
    async ({ visitor_name, host_name, company, purpose }) => {
      const visit = createVisit({ visitor_name, host_name, company, purpose });
      return {
        content: [{ type: 'text', text: JSON.stringify({ id: visit.id, checked_in_at: visit.checked_in_at }) }],
      };
    }
  );

  server.tool(
    'checkout_visitor',
    'Check out a visitor by their visit ID.',
    { visit_id: z.string() },
    async ({ visit_id }) => {
      const visit = checkoutVisit(visit_id);
      if (!visit) {
        return { content: [{ type: 'text', text: 'Visit not found.' }], isError: true };
      }
      return {
        content: [{ type: 'text', text: JSON.stringify({ id: visit.id, checked_out_at: visit.checked_out_at }) }],
      };
    }
  );

  // Returns timing + status only — no visitor names in agent context.
  server.tool(
    'get_visit_status',
    'Get check-in/out times and status for a visit. No PII returned.',
    { visit_id: z.string() },
    async ({ visit_id }) => {
      const visit = getVisit(visit_id);
      if (!visit) {
        return { content: [{ type: 'text', text: 'Visit not found.' }], isError: true };
      }
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              id: visit.id,
              status: visit.checked_out_at ? 'checked_out' : 'on_site',
              checked_in_at: visit.checked_in_at,
              checked_out_at: visit.checked_out_at,
            }),
          },
        ],
      };
    }
  );

  // Aggregates only — safe to include in any AI model context.
  server.tool(
    'get_today_summary',
    'Return aggregate visit counts for today. No PII — safe for Bedrock context.',
    {},
    async () => {
      const summary = getTodaySummary();
      return { content: [{ type: 'text', text: JSON.stringify(summary) }] };
    }
  );

  return server;
}

const app = express();
app.use(express.json());

app.get('/mcp/health', (_req, res) => res.json({ status: 'ok', server: 'frontdesk-mcp' }));

app.post('/mcp', async (req, res) => {
  const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
  const server = buildServer();
  res.on('close', async () => { await server.close().catch(() => {}); });
  try {
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  } catch (err) {
    if (!res.headersSent) {
      res.status(500).json({ error: 'Internal MCP error', detail: err.message });
    }
  }
});

app.listen(PORT, () => console.log(`FrontDesk MCP server listening on port ${PORT}`));
