const { spawn } = require('child_process');
const path = require('path');

// Helper function to run Docker commands
function runDockerCommand(command, args, options = {}) {
    return new Promise((resolve, reject) => {
        console.log(`🐳 Running: ${command} ${args.join(' ')}`);

        const child = spawn(command, args, {
            stdio: 'inherit',
            shell: true,
            cwd: path.resolve(__dirname, '..'),
            ...options
        });

        child.on('error', (error) => {
            console.error(`❌ Error running ${command}:`, error.message);
            reject(error);
        });

        child.on('exit', (code) => {
            if (code === 0) {
                console.log(`✅ ${command} completed successfully`);
                resolve();
            } else {
                console.error(`❌ ${command} exited with code ${code}`);
                reject(new Error(`${command} exited with code ${code}`));
            }
        });
    });
}

// Main function to handle different Docker operations
async function main() {
    const action = process.argv[2];
    const environment = process.argv[3] || 'dev';

    try {
        switch (action) {
            case 'start':
                if (environment === 'dev') {
                    await runDockerCommand('docker-compose', [
                        '-f', 'docker-compose.dev.yml',
                        'up', '--build'
                    ]);
                } else {
                    await runDockerCommand('docker-compose', [
                        'up', '--build'
                    ]);
                }
                break;

            case 'build':
                if (environment === 'dev') {
                    await runDockerCommand('docker-compose', [
                        '-f', 'docker-compose.dev.yml',
                        'build', '--no-cache'
                    ]);
                } else {
                    await runDockerCommand('docker-compose', [
                        'build', '--no-cache'
                    ]);
                }
                break;

            case 'stop':
                if (environment === 'dev') {
                    await runDockerCommand('docker-compose', [
                        '-f', 'docker-compose.dev.yml',
                        'down'
                    ]);
                } else {
                    await runDockerCommand('docker-compose', [
                        'down'
                    ]);
                }
                break;

            case 'clean':
                await runDockerCommand('docker', [
                    'system', 'prune', '-f'
                ]);
                await runDockerCommand('docker', [
                    'volume', 'prune', '-f'
                ]);
                break;

            case 'logs':
                if (environment === 'dev') {
                    await runDockerCommand('docker-compose', [
                        '-f', 'docker-compose.dev.yml',
                        'logs', '-f'
                    ]);
                } else {
                    await runDockerCommand('docker-compose', [
                        'logs', '-f'
                    ]);
                }
                break;

            default:
                console.log('🐳 Docker Runner Commands:');
                console.log('  start [dev|prod] - Start Docker services');
                console.log('  build [dev|prod] - Build Docker images');
                console.log('  stop [dev|prod]  - Stop Docker services');
                console.log('  clean            - Clean Docker system');
                console.log('  logs [dev|prod]  - Show Docker logs');
                console.log('');
                console.log('Examples:');
                console.log('  node scripts/docker-runner.js start dev');
                console.log('  node scripts/docker-runner.js build prod');
                console.log('  node scripts/docker-runner.js stop dev');
                break;
        }
    } catch (error) {
        console.error('❌ Docker operation failed:', error.message);
        process.exit(1);
    }
}

// Handle process termination
process.on('SIGINT', () => {
    console.log('\n🛑 Docker operation interrupted');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Docker operation terminated');
    process.exit(0);
});

// Run if called directly
if (require.main === module) {
    main().catch((error) => {
        console.error('❌ Fatal error:', error.message);
        process.exit(1);
    });
}

module.exports = {
    runDockerCommand,
    main
}; 