const API_BASE_URL = 'http://localhost:3000/api';

document.addEventListener('DOMContentLoaded', () => {
    console.log('Guardian Dashboard Initialized');

    // Initial fetch
    fetchDashboardData();
    fetchAlerts();

    // Polling for live updates
    setInterval(() => {
        fetchDashboardData();
        fetchAlerts();
        addConsoleLog('System Heartbeat: All sensors operational', 'info');
    }, 5000);
});

async function fetchDashboardData() {
    try {
        const response = await fetch(`${API_BASE_URL}/stats`);
        const data = await response.json();

        document.querySelector('.stat-card:nth-child(1) .stat-value').innerText = data.activeBands.toLocaleString();
        document.querySelector('.stat-card:nth-child(2) .stat-value').innerText = data.alertsToday;
        document.querySelector('.stat-card:nth-child(3) .stat-value').innerText = data.systemHealth;
    } catch (error) {
        console.error('Error fetching stats:', error);
    }
}

async function fetchAlerts() {
    try {
        const response = await fetch(`${API_BASE_URL}/alerts`);
        const alerts = await response.json();
        renderAlerts(alerts);
    } catch (error) {
        console.error('Error fetching alerts:', error);
    }
}

function renderAlerts(alerts) {
    const alertList = document.querySelector('.alert-list');
    alertList.innerHTML = ''; // Clear current list

    alerts.forEach(alert => {
        const badgeClass = alert.status === 'Emergency' ? 'badge-emergency' : 'badge-resolved';
        const alertHTML = `
            <div class="alert-item">
                <div class="alert-meta">
                    <h4>Device #${alert.id}</h4>
                    <span>${alert.time} • ${alert.location}</span>
                </div>
                <span class="badge ${badgeClass}">${alert.status}</span>
            </div>
        `;
        alertList.insertAdjacentHTML('beforeend', alertHTML);
    });
}

function addConsoleLog(message, type) {
    const consoleBody = document.getElementById('console-body');
    if (!consoleBody) return;

    const time = new Date().toLocaleTimeString([], { hour12: false });
    const logEntry = document.createElement('div');
    logEntry.className = `log-entry log-${type}`;
    logEntry.innerHTML = `<span class="log-time">[${time}]</span> <span class="log-msg">${message}</span>`;

    consoleBody.appendChild(logEntry);
    consoleBody.scrollTop = consoleBody.scrollHeight;
}

// Keeping this for simulation if needed, but now it could actually POST to backend
async function triggerSOS() {
    try {
        const response = await fetch(`${API_BASE_URL}/alerts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                deviceId: `SIM-${Math.floor(Math.random() * 9000) + 1000}`,
                latitude: 27.7172,
                longitude: 85.3240,
                status: 'Emergency'
            })
        });
        const result = await response.json();
        addConsoleLog(`CRITICAL: Manual SOS triggered for ${result.alert.id}`, 'error');
        fetchAlerts();
    } catch (error) {
        console.error('Error triggering SOS:', error);
    }
}
