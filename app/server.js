const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

// Health check endpoint — returns 200 so a load balancer or cluster can check it
app.get('/health', (_req, res) => {
  res.status(200).send('OK');
});

// Root endpoint
app.get('/', (_req, res) => {
  res.status(200).send('Hello world');
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
