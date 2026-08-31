export const log = {
  info: (message, ...args) => {
    console.info(`ℹ️ ${message}`, ...args);
  },
  error: (message, ...args) => {
    console.error(`🔴 ${message}`, ...args);
  },
  success: (message, ...args) => {
    console.log(`🟢 ${message}`, ...args);
  },
};
