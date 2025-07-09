const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

// Check if a process is running by name or port
async function isProcessRunning(identifier) {
    try {
        if (identifier.includes(':')) {
            // Check by port
            const port = identifier.split(':')[1];
            const { stdout } = await execAsync(`netstat -ano | findstr :${port}`);
            return stdout.trim().length > 0;
        } else {
            // Check by process name
            const { stdout } = await execAsync(`tasklist /FI "IMAGENAME eq ${identifier}"`);
            return stdout.includes(identifier);
        }
    } catch (error) {
        return false;
    }
}

// Kill processes by name
async function killProcessByName(processName) {
    try {
        console.log(`🛑 Stopping existing ${processName} processes...`);
        await execAsync(`taskkill /F /IM ${processName}`);
        console.log(`✅ Killed ${processName} processes`);
        return true;
    } catch (error) {
        console.log(`ℹ️  No ${processName} processes found`);
        return false;
    }
}

// Kill processes by port
async function killProcessByPort(port) {
    try {
        console.log(`🛑 Stopping processes on port ${port}...`);
        const { stdout } = await execAsync(`netstat -ano | findstr :${port}`);
        const lines = stdout.trim().split('\n');

        for (const line of lines) {
            const parts = line.trim().split(/\s+/);
            if (parts.length >= 5) {
                const pid = parts[4];
                try {
                    await execAsync(`taskkill /F /PID ${pid}`);
                    console.log(`✅ Killed process ${pid} on port ${port}`);
                } catch (error) {
                    // Process might already be dead
                }
            }
        }
        return true;
    } catch (error) {
        console.log(`ℹ️  No processes found on port ${port}`);
        return false;
    }
}

// Clean up all development processes
async function cleanupDevProcesses() {
    console.log('🧹 Cleaning up development processes...\n');

    const processesToKill = [
        'ts-node.exe',
        'nodemon.exe'
    ];

    const portsToCheck = [
        '4000',  // API
        '5173',  // Frontend
        '5174',  // Frontend fallback
        '4001',  // API fallback
        '4002'   // API fallback
    ];

    // Kill by process name
    for (const process of processesToKill) {
        await killProcessByName(process);
    }

    // Kill by port
    for (const port of portsToCheck) {
        await killProcessByPort(port);
    }

    console.log('✅ Cleanup complete!\n');
}

// Check for conflicting processes
async function checkForConflicts() {
    console.log('🔍 Checking for conflicting processes...\n');

    const conflicts = [];

    // Check our main ports
    const portChecks = [
        { port: '4000', service: 'API Server' },
        { port: '5173', service: 'Frontend' }
    ];

    for (const check of portChecks) {
        const isRunning = await isProcessRunning(`:${check.port}`);
        if (isRunning) {
            conflicts.push({
                type: 'port',
                identifier: check.port,
                service: check.service
            });
        }
    }

    // Check for multiple Node.js processes
    try {
        const { stdout } = await execAsync('tasklist /FI "IMAGENAME eq node.exe"');
        const nodeProcesses = stdout.split('\n').filter(line => line.includes('node.exe')).length - 1;

        if (nodeProcesses > 3) { // Allow for our 3 services
            conflicts.push({
                type: 'process',
                identifier: 'node.exe',
                count: nodeProcesses,
                message: `Found ${nodeProcesses} Node.js processes (expected 3 or fewer)`
            });
        }
    } catch (error) {
        // No Node.js processes found
    }

    return conflicts;
}

// Display process status
async function displayProcessStatus() {
    console.log('📊 Development Process Status\n');

    try {
        const { stdout } = await execAsync('tasklist /FI "IMAGENAME eq node.exe"');
        const lines = stdout.split('\n').filter(line => line.includes('node.exe'));

        console.log(`🤖 Node.js Processes: ${lines.length}`);
        lines.forEach((line, index) => {
            const parts = line.trim().split(/\s+/);
            if (parts.length >= 5) {
                console.log(`   ${index + 1}. PID: ${parts[1]} | Memory: ${parts[4]}`);
            }
        });

        // Check ports
        const ports = ['4000', '5173', '5174'];
        for (const port of ports) {
            const isRunning = await isProcessRunning(`:${port}`);
            const status = isRunning ? '🔴 In Use' : '🟢 Available';
            console.log(`   Port ${port}: ${status}`);
        }

    } catch (error) {
        console.log('ℹ️  No Node.js processes found');
    }

    console.log('');
}

// Main function
async function main() {
    const command = process.argv[2] || 'check';

    switch (command) {
        case 'cleanup':
            await cleanupDevProcesses();
            break;
        case 'check':
            const conflicts = await checkForConflicts();
            if (conflicts.length > 0) {
                console.log('⚠️  Found conflicts:');
                conflicts.forEach(conflict => {
                    if (conflict.type === 'port') {
                        console.log(`   - Port ${conflict.identifier} is in use by ${conflict.service}`);
                    } else {
                        console.log(`   - ${conflict.message}`);
                    }
                });
                console.log('\n💡 Run "npm run cleanup" to fix conflicts');
            } else {
                console.log('✅ No conflicts found');
            }
            break;
        case 'status':
            await displayProcessStatus();
            break;
        case 'help':
            console.log('🛠️  Process Manager Commands:');
            console.log('  cleanup - Kill all development processes');
            console.log('  check   - Check for conflicts');
            console.log('  status  - Show process status');
            console.log('  help    - Show this help');
            break;
        default:
            console.log('❌ Unknown command. Use "help" for available commands.');
    }
}

// Run if called directly
if (require.main === module) {
    process.on('uncaughtException', (err) => {
        console.error('Uncaught exception in cleanup:', err);
        process.exit(0);
    });
    process.on('unhandledRejection', (reason) => {
        console.error('Unhandled rejection in cleanup:', reason);
        process.exit(0);
    });
    main().catch(console.error);
}

module.exports = {
    cleanupDevProcesses,
    checkForConflicts,
    displayProcessStatus,
    isProcessRunning,
    killProcessByName,
    killProcessByPort
}; 