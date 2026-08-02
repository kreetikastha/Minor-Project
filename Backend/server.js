const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

// Mock database for users
let users = [
    { email: "user@guardian.com", password: "password123" },
    { email: "admin@guardian.com", password: "adminpassword" }
];

// In-memory storage for alerts
let alerts = [
    {
        id: "GB-8842",
        status: "Resolved",
        location: "Boudha, KTM",
        time: "10:45 AM",
        timestamp: new Date(Date.now() - 3600000)
    }
];

// Login Endpoint
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;
    const user = users.find(u => u.email === email && u.password === password);

    if (user) {
        console.log(`Login successful: ${email}`);
        res.status(200).json({ message: "Login successful", user: { email: user.email } });
    } else {
        console.log(`Login failed: ${email}`);
        res.status(401).json({ message: "Invalid email or password" });
    }
});

// Endpoint for the Mobile App to send alerts
app.post('/api/alerts', (req, res) => {
    const { deviceId, latitude, longitude, status } = req.body;

    const newAlert = {
        id: deviceId || `GB-${Math.floor(Math.random() * 9000) + 1000}`,
        status: status || "Emergency",
        location: latitude && longitude ? `${latitude.toFixed(4)}, ${longitude.toFixed(4)}` : "Unknown Location",
        latitude: latitude,
        longitude: longitude,
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        timestamp: new Date()
    };

    alerts.unshift(newAlert);
    console.log('New Alert Received:', newAlert);
    res.status(201).json({ message: "Alert recorded successfully", alert: newAlert });
});

app.get('/api/alerts', (req, res) => {
    res.json(alerts);
});

app.get('/api/stats', (req, res) => {
    res.json({
        activeBands: 1208 + Math.floor(Mathgit .random() * 10),
        alertsToday: alerts.length,
        systemHealth: "99%"
    });
});

app.listen(PORT, () => {
    console.log(`Guardian Backend running on http://localhost:${PORT}`);
});
