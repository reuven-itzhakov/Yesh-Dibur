// jest.setup.js

beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
  jest.spyOn(console, 'log').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
  console.log.mockRestore();
});

// Mock מקיף יותר עבור Winston
jest.mock('winston', () => {
  const mLogger = {
    log: jest.fn().mockReturnThis(),
    info: jest.fn().mockReturnThis(),
    error: jest.fn().mockReturnThis(),
    warn: jest.fn().mockReturnThis(),
    debug: jest.fn().mockReturnThis(),
    child: jest.fn().mockReturnThis(),
  };

  // משתמשים ב-Proxy כדי שכל תתי-הפונקציות של format (כמו errors, json, וכו')
  // יחזירו אוטומטית פונקציית דמה ולא יגרמו ל-TypeError
  const formatMock = new Proxy({}, {
    get: () => jest.fn().mockReturnThis()
  });

  return {
    format: formatMock,
    transports: {
      Console: jest.fn(),
      File: jest.fn(),
    },
    createLogger: jest.fn(() => mLogger),
    ...mLogger
  };
});