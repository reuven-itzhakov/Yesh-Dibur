const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.POSTGRES_USER,
  host: process.env.POSTGRES_HOST,
  database: process.env.POSTGRES_DB,
  password: process.env.POSTGRES_PASSWORD,
  port: process.env.POSTGRES_PORT || 5432,
  // אטימת קריסות שרת: ניהול חכם של עומסים ומשאבים (Connection Pooling)
  max: 50, // מקסימום 50 חיבורים מקבילים כדי לא להחניק את מסד הנתונים
  idleTimeoutMillis: 30000, // ניתוק חיבורים שלא היו בשימוש חצי דקה כדי לשחרר זיכרון
  connectionTimeoutMillis: 5000 // ביטול ניסיונות חיבור שנתקעו מעל 5 שניות
});

// אטימת קריסת שרת פתאומית: טיפול בניתוקים של חיבורי מסד נתונים שממתינים ברקע
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle PostgreSQL client:', err.message);
  process.exit(-1); // יגרום ל-Docker או PM2 להרים את השרת מחדש עם חיבורים טריים
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
