const { spawn } = require('child_process');
const path = require('path');
const { isPortAvailable, findFreePort, config } = require('./port-manager');
const { checkForConflicts, cleanupDevProcesses } = require('./process-manager');

console.log('🎲 Starting D&D Campaign Organizer Services...\n');

// Check for conflicts before starting
async function checkForConflictsBeforeStart() {
    console.log('🔍 Checking for existing processes...');
    const conflicts = await checkForConflicts();

    if (conflicts.length > 0) {
        console.log('⚠️  Found conflicts. Cleaning up...\n');
        await cleanupDevProcesses();
        console.log('✅ Cleanup complete. Starting fresh...\n');
    } else {
        console.log('✅ No conflicts found. Starting services...\n');
    }
}

// Function to get the correct port for a service
async function getServicePort(serviceName) {
    const service = config.services[serviceName];
    if (!service.port) return null;

    const isAvailable = await isPortAvailable(service.port);
    if (isAvailable) {
        return service.port;
    }

    // Try fallback ports
    const fallbackPorts = config.development.fallbackPorts[serviceName] || [];
    const freePort = await findFreePort(fallbackPorts);

    if (freePort) {
        console.log(`⚠️  Port ${service.port} is in use, using ${freePort} for ${service.name}`);
        return freePort;
    }

    console.log(`❌ No free ports available for ${service.name}`);
    return null;
}

// Function to start a service
async function startService(name, command, args, cwd) {
    console.log(`🚀 Starting ${name}...`);

    let port = null;
    if (cwd.includes('api')) {
        port = await getServicePort('api');
    } else if (cwd.includes('frontend')) {
        port = await getServicePort('frontend');
    }

    const env = {
        ...process.env,
        NODE_ENV: 'development'
    };

    if (port) {
        env.PORT = port.toString();
    }

    const child = spawn(command, args, {
        cwd: path.resolve(__dirname, '..', cwd),
        stdio: 'inherit',
        shell: true,
        env
    });

    child.on('error', (error) => {
        console.error(`❌ Error starting ${name}:`, error.message);
    });

    child.on('exit', (code) => {
        if (code !== 0) {
            console.error(`❌ ${name} exited with code ${code}`);
        }
    });

    return child;
}

// Start all services
const services = [
    {
        name: 'Frontend (React)',
        command: 'npm',
        args: ['run', 'dev'],
        cwd: 'apps/frontend'
    },
    {
        name: 'API Server',
        command: 'npm',
        args: ['run', 'dev'],
        cwd: 'apps/api'
    },
    {
        name: 'Discord Bot',
        command: 'npm',
        args: ['run', 'dev'],
        cwd: 'apps/discord-bot'
    }
];

async function startAllServices() {
    // Check for conflicts first
    await checkForConflictsBeforeStart();

    const processes = [];

    for (const service of services) {
        const process = await startService(service.name, service.command, service.args, service.cwd);
        processes.push(process);
    }

    // Handle process termination
    process.on('SIGINT', () => {
        console.log('\n🛑 Stopping all services...');
        processes.forEach(process => process.kill('SIGINT'));
        process.exit(0);
    });

    process.on('SIGTERM', () => {
        console.log('\n🛑 Stopping all services...');
        processes.forEach(process => process.kill('SIGTERM'));
        process.exit(0);
    });

    console.log('✅ All services started! Press Ctrl+C to stop all services.\n');
}

startAllServices().catch(console.error); 