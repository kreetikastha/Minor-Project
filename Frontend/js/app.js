document.addEventListener('DOMContentLoaded', () => {
    console.log('Guardian Dashboard Initialized');

    // Auto-update timestamps or mock data
    setInterval(() => {
        updateStats();
        addConsoleLog('System Heartbeat: All sensors operational', 'info');
    }, 15000);
});

function updateStats() {
    console.log('Refreshing dashboard data...');
    // Randomly fluctuate active bands to look "live"
    const activeCount = document.querySelector('.stat-value');
    if (activeCount) {
        const current = parseInt(activeCount.innerText.replace(',', ''));
        const change = Math.floor(Math.random() * 5) - 2;
        activeCount.innerText = (current + change).toLocaleString();
    }
}

function triggerSOS() {
    const alertList = document.querySelector('.alert-list');
    const deviceId = `GB-${Math.floor(Math.random() * 9000) + 1000}`;
    const time = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const location = "Kathmandu, NP";

    const alertHTML = `
        <div class="alert-item" style="animation: slideIn 0.3s ease-out">
            <div class="alert-meta">
                <h4>Device #${deviceId}</h4>
                <span>Just now • ${location}</span>
            </div>
            <span class="badge badge-emergency">Emergency</span>
        </div>
    `;

    alertList.insertAdjacentHTML('afterbegin', alertHTML);

    // Add to console log
    addConsoleLog(`CRITICAL: SOS signal received from ${deviceId}`, 'error');

    // Play sound or notification logic
    showNotification(`EMERGENCY: SOS triggered by #${deviceId}`);
}

function addConsoleLog(message, type) {
    // This assumes we add a console panel to the HTML
    const consoleBody = document.getElementById('console-body');
    if (!consoleBody) return;

    const time = new Date().toLocaleTimeString([], { hour12: false });
    const logEntry = document.createElement('div');
    logEntry.className = `log-entry log-${type}`;
    logEntry.innerHTML = `<span class="log-time">[${time}]</span> <span class="log-msg">${message}</span>`;

    consoleBody.appendChild(logEntry);
    consoleBody.scrollTop = consoleBody.scrollHeight;
}

function showNotification(message) {
    if ("Notification" in window) {
        if (Notification.permission === "granted") {
            new Notification("Guardian Alert", { body: message });
        } else if (Notification.permission !== "denied") {
            Notification.requestPermission();
        }
    }
}
