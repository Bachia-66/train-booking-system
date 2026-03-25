const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

// Run: npm install bcrypt jsonwebtoken
const bcrypt = require('bcrypt');      // For password hashing
const jwt = require('jsonwebtoken');   // For JWT tokens

console.log("Server starting...");

const app = express();
app.use(express.json());
app.use(cors());

// ========== NEW: JWT Secret Key ==========
const JWT_SECRET = 'your-secret-key-change-in-production';

// Serve frontend files from the 'frontend' folder
const path = require('path');

// Serve frontend from ../frontend
app.use(express.static(path.join(__dirname, '../frontend')));

// Optional: make / load index.html automatically
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'train_system'
});

db.connect(err => {
    if (err) {
        console.log("DB Error:", err);
    } else {
        console.log("MySQL Connected");
    }
});

// ========== Authentication Middleware ==========
// This verifies the JWT token before allowing access to protected routes
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access denied. Please login.' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid or expired token.' });
        }
        req.user = user;
        next();
    });
};

// ========== User Registration Endpoint ==========
app.post('/api/register', async (req, res) => {
    const { username, email, password, full_name, phone } = req.body;

    if (!username || !email || !password) {
        return res.status(400).json({ error: 'Username, email, and password required.' });
    }

    // Check if user exists
    db.query(
        'SELECT * FROM users WHERE username = ? OR email = ?',
        [username, email],
        async (err, results) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (results.length > 0) {
                return res.status(409).json({ error: 'Username or email already exists' });
            }

            const hashedPassword = await bcrypt.hash(password, 10);

            db.query(
                `INSERT INTO users (username, email, password_hash, full_name, phone) 
                 VALUES (?, ?, ?, ?, ?)`,
                [username, email, hashedPassword, full_name || null, phone || null],
                (err, result) => {
                    if (err) return res.status(500).json({ error: 'Registration failed' });
                    res.status(201).json({ message: 'User registered successfully!' });
                }
            );
        }
    );
});

// ========== User Login Endpoint ==========
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ error: 'Username and password required.' });
    }

    db.query(
        'SELECT * FROM users WHERE username = ? OR email = ?',
        [username, username],
        async (err, results) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (results.length === 0) {
                return res.status(401).json({ error: 'Invalid credentials' });
            }

            const user = results[0];
            const validPassword = await bcrypt.compare(password, user.password_hash);
            
            if (!validPassword) {
                return res.status(401).json({ error: 'Invalid credentials' });
            }

            const token = jwt.sign(
                { user_id: user.user_id, username: user.username },
                JWT_SECRET,
                { expiresIn: '24h' }
            );

            res.json({
                message: 'Login successful!',
                token: token,
                user: {
                    user_id: user.user_id,
                    username: user.username,
                    email: user.email,
                    full_name: user.full_name
                }
            });
        }
    );
});

// ========== Trains endpoint (now protected) ==========
// Your original endpoint is now protected - requires login
app.get('/trains', authenticateToken, (req, res) => {
    console.log("GET /trains called");

    db.query('SELECT * FROM trains', (err, results) => {
        if (err) {
            console.log("Query error:", err);
            return res.status(500).json(err);
        }
        res.json(results);
    });
});

// ========== Search endpoint with source/destination ==========
app.get('/api/trains/search', authenticateToken, (req, res) => {
    const { source, destination } = req.query;
    
    
    //  simple query that matches trains to stations
    let query = `
        SELECT DISTINCT t.* 
        FROM trains t
        JOIN train_routes tr1 ON t.train_id = tr1.train_id
        JOIN stations s1 ON tr1.station_id = s1.station_id
        JOIN train_routes tr2 ON t.train_id = tr2.train_id
        JOIN stations s2 ON tr2.station_id = s2.station_id
        WHERE s1.station_name LIKE ? 
        AND s2.station_name LIKE ?
        AND tr1.stop_order < tr2.stop_order
    `;
    
    db.query(query, [`%${source}%`, `%${destination}%`], (err, results) => {
        if (err) {
            console.log("Search error:", err);
            return res.status(500).json({ error: 'Search failed' });
        }
        res.json(results);
    });
});

// ========== Booking =========
app.post('/api/book', authenticateToken, (req, res) => {
    const { train_id, seats } = req.body;
    const user_id = req.user.user_id;

    if (!train_id || !seats || seats < 1) {
        return res.status(400).json({ error: 'Train ID and valid seats required.' });
    }

    // Generate PNR number
    const pnr = 'PNR' + Date.now() + Math.floor(Math.random() * 1000);

    db.query(
        `INSERT INTO bookings (user_id, train_id, pnr_number, seats_booked, booking_date, travel_date, status)
         VALUES (?, ?, ?, ?, CURDATE(), CURDATE(), 'confirmed')`,
        [user_id, train_id, pnr, seats],
        (err, result) => {
            if (err) {
                console.log("Booking error:", err);
                return res.status(500).json({ error: 'Booking failed' });
            }
            res.json({ 
                message: 'Booking successful!', 
                booking_id: result.insertId,
                pnr: pnr
            });
        }
    );
});

// ========== NEW: Get user's bookings ==========
app.get('/api/bookings', authenticateToken, (req, res) => {
    const user_id = req.user.user_id;

    db.query(
        `SELECT b.*, t.train_name, t.train_number 
         FROM bookings b
         JOIN trains t ON b.train_id = t.train_id
         WHERE b.user_id = ?
         ORDER BY b.booking_date DESC`,
        [user_id],
        (err, results) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json(results);
        }
    );
});


app.get('/', (req, res) => {
    res.send("Server is working!");
});

app.get('/test', (req, res) => {
    res.send("TEST WORKING");
});

app.listen(3000, () => {
    console.log("Server running on port 3000");
});