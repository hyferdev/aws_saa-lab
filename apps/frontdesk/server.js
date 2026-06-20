import express from 'express';
import { createVisit, checkoutVisit, getTodayVisits } from './db.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.get('/', (_req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head><title>FrontDesk</title></head>
    <body>
      <h1>FrontDesk — Guest Check-In</h1>
      <form method="POST" action="/checkin">
        <p><input name="visitor_name" placeholder="Visitor name" required></p>
        <p><input name="host_name" placeholder="Host name" required></p>
        <p><input name="company" placeholder="Company (optional)"></p>
        <p><input name="purpose" placeholder="Purpose (optional)"></p>
        <button type="submit">Check In</button>
      </form>
      <p><a href="/today">Today's visits</a></p>
    </body>
    </html>
  `);
});

app.post('/checkin', (req, res) => {
  const { visitor_name, host_name, company, purpose } = req.body;
  if (!visitor_name || !host_name) {
    return res.status(400).json({ error: 'visitor_name and host_name are required' });
  }
  const visit = createVisit({ visitor_name, host_name, company, purpose });
  res.status(201).json(visit);
});

app.post('/checkout/:id', (req, res) => {
  const visit = checkoutVisit(req.params.id);
  if (!visit) return res.status(404).json({ error: 'Visit not found' });
  res.json(visit);
});

app.get('/today', (_req, res) => {
  res.json(getTodayVisits());
});

app.listen(PORT, () => console.log(`FrontDesk app listening on port ${PORT}`));
