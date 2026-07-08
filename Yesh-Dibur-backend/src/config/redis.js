const redis = require('redis');

const redisClient = redis.createClient({
  url: process.env.REDIS_URI,
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.on('connect', () => console.log('Redis connected'));

const connectRedis = async () => {
  try {
    await redisClient.connect();
  } catch (error) {
    console.error(`Redis connection error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = { redisClient, connectRedis };
