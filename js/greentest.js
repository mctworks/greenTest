const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');
const http = require('http');

console.log("Vanilla Compost GreenTest JS runner");
console.log("===================================");

const VANILLA_COMPOST = process.env.VANILLA_COMPOST || "../../vanilla-compost";
console.log(`Step 1: Using vanilla-compost at: ${VANILLA_COMPOST}`);

// Step 2: Confirm clone
const destDir = path.resolve(VANILLA_COMPOST);
const readmePath = path.join(destDir, 'README.md');
const generatorPath = path.join(destDir, 'src', 'generate_posts.js');

if (!fs.existsSync(readmePath) || !fs.existsSync(generatorPath)) {
    console.error(`Error: Path does not look like a vanilla-compost clone with JS generator: ${destDir}`);
    process.exit(1);
}
console.log("Step 2: Repo layout confirmed (found README.md and generate_posts.js).");

// Step 3: Leave a note
const logPath = "greentest-log.md";
const timestamp = new Date().toISOString().slice(0, 16).replace('T', ' ');

function writeNotesAndProceed(notes) {
    const logContent = `## ${timestamp}\n\n${notes.trim()}\n\n`;
    fs.appendFileSync(logPath, logContent, 'utf8');
    console.log(`Step 3: Notes appended to ${logPath}`);

    // Step 4: Copy greentest-log.md to posts/ directory in vanilla-compost
    const postsDir = path.join(destDir, 'src', 'posts');
    if (!fs.existsSync(postsDir)) {
        fs.mkdirSync(postsDir, { recursive: true });
    }
    fs.copyFileSync(logPath, path.join(postsDir, logPath));
    console.log(`Step 4: Copied ${logPath} to ${postsDir}/`);

    // Step 5: Generate posts.html
    console.log("Step 5: Generating posts.html...");
    try {
        const genOutput = execSync(`node ${generatorPath}`, { cwd: path.join(destDir, 'src'), encoding: 'utf8' });
        console.log(genOutput.trim());
    } catch (err) {
        console.error("Failed to generate posts.html:", err.message);
        process.exit(1);
    }

    // Step 6: Serve the site locally
    console.log("Step 6: Starting Node.js server...");
    const serverProcess = spawn('node', ['server.js', path.join(destDir, 'src')], {
        stdio: 'ignore'
    });

    // Step 7: Verify serving
    setTimeout(() => {
        console.log("Step 7: Verifying served content...");
        http.get('http://localhost:8080/posts.html', (res) => {
            let data = '';
            res.on('data', chunk => { data += chunk; });
            res.on('end', () => {
                const generatedHtml = fs.readFileSync(path.join(destDir, 'src', 'posts.html'), 'utf8');
                if (data === generatedHtml && data.includes('hello-compost')) {
                    console.log("\n\x1b[32mGreen: the Node.js server is serving the freshly generated posts.html.\x1b[0m\n");
                } else {
                    console.error("Verification failed! Served content does not match or missing hello-compost.");
                    serverProcess.kill();
                    process.exit(1);
                }
                
                // Step 8: Clean up
                console.log("Step 8: Cleaning up...");
                serverProcess.kill();
                console.log("Server stopped.");
                process.exit(0);
            });
        }).on('error', (err) => {
            console.error("Failed to connect to the server:", err.message);
            serverProcess.kill();
            process.exit(1);
        });
    }, 1000);
}

// Ask for input if stdin is interactive
if (process.stdin.isTTY) {
    const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
    });
    readline.question("Enter notes for this run (or press Enter for default): ", (input) => {
        readline.close();
        const notes = input.trim() || "Hello, World! (Node.js validation run)";
        writeNotesAndProceed(notes);
    });
} else {
    const notes = "Hello, World! (Node.js automated validation run)";
    writeNotesAndProceed(notes);
}
