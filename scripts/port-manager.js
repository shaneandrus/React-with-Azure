const net = require('net');
const fs = require('fs');
const path = require('path');

// Load port configuration
const configPath = path.join(__dirname, '..', 'config', 'ports.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

// Check if a port is available
function isPortAvailable(port) {
    return new Promise((resolve) => {
        const server = net.createServer();
        server.listen(port, () => {
            server.once('close', () => {
                resolve(true);
            });
            server.close();
        });
        server.on('error', () => {
            resolve(false);
        });
    });
}

// Find a free port from a list
async function findFreePort(ports) {
    for (const port of ports) {
        if (await isPortAvailable(port)) {
            return port;
        }
    }
    return null;
}

// Get service status
async function getServiceStatus() {
    const status = {};

    for (const [serviceName, service] of Object.entries(config.services)) {
        if (service.port) {
            const isAvailable = await isPortAvailable(service.port);
            status[serviceName] = {
                ...service,
                available: isAvailable,
                status: isAvailable ? '🟢 Available' : '🔴 In Use'
            };
        } else {
            status[serviceName] = {
                ...service,
                available: null,
                status: '⚪ No Port'
            };
        }
    }

    return status;
}

// Display service status
async function displayStatus() {
    console.log('🎲 D&D Campaign Organizer - Service Status\n');

    const status = await getServiceStatus();

    for (const [serviceName, service] of Object.entries(status)) {
        const icon = service.available === null ? '⚪' : (service.available ? '🟢' : '🔴');
        const portInfo = service.port ? `:${service.port}` : '';
        const urlInfo = service.url ? ` (${service.url})` : '';

        console.log(`${icon} ${service.name}${portInfo}${urlInfo}`);
        console.log(`   ${service.description}`);
        console.log(`   Status: ${service.status}\n`);
    }
}

// Find alternative ports
async function findAlternativePorts() {
    console.log('🔍 Finding alternative ports...\n');

    for (const [serviceName, fallbackPorts] of Object.entries(config.development.fallbackPorts)) {
        const service = config.services[serviceName];
        const currentPort = service.port;
        const isCurrentAvailable = await isPortAvailable(currentPort);

        if (!isCurrentAvailable) {
            console.log(`⚠️  ${service.name} (port ${currentPort}) is in use`);

            const freePort = await findFreePort(fallbackPorts);
            if (freePort) {
                console.log(`   → Try port ${freePort} instead`);
                console.log(`   → Update config/ports.json or set PORT=${freePort}\n`);
            } else {
                console.log(`   → No free ports found in fallback list\n`);
            }
        }
    }
}

// Main function
async function main() {
    const command = process.argv[2] || 'status';

    switch (command) {
        case 'status':
            await displayStatus();
            break;
        case 'check':
            await findAlternativePorts();
            break;
        case 'help':
            console.log('🎲 Port Manager Commands:');
            console.log('  status  - Show all service status');
            console.log('  check   - Find alternative ports');
            console.log('  help    - Show this help');
            break;
        default:
            console.log('❌ Unknown command. Use "help" for available commands.');
    }
}

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = {
    isPortAvailable,
    findFreePort,
    getServiceStatus,
    config
}; 