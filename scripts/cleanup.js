const { cleanupDevProcesses } = require('./process-manager');

// Catch any unhandled promise rejections
process.on('unhandledRejection', (reason) => {
    console.error('Unhandled rejection in cleanup:', reason);
    process.exit(0);
});

(async () => {
    try {
        await cleanupDevProcesses();
        process.exit(0);
    } catch (e) {
        console.error('Cleanup error:', e);
        process.exit(0); // Always exit 0, even on error
    }
})();