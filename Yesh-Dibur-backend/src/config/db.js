const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.POSTGRES_USER,
  host: process.env.POSTGRES_HOST,
  database: process.env.POSTGRES_DB,
  password: process.env.POSTGRES_PASSWORD,
  port: process.env.POSTGRES_PORT || 5432
});

const connectDB = async () => {
  try {
    const client = await pool.connect();
    console.log(`PostgreSQL connected: ${client.host}`);
    client.release();
  } catch (error) {
    console.error(`PostgreSQL connection error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = { pool, connectDB };
