// 3. FRONTEND JS (script.js)

// Global variables for authentication
let authToken = null;
let currentUser = null;

// ==========  Authentication Functions ==========

async function login() {
    const username = document.getElementById('login-username').value;
    const password = document.getElementById('login-password').value;
    const messageDiv = document.getElementById('login-message');

    if (!username || !password) {
        messageDiv.innerHTML = '<div class="message error">Enter username/email and password</div>';
        return;
    }

    messageDiv.innerHTML = '<div class="message">Logging in...</div>';

    try {
        const response = await fetch('http://localhost:3000/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });

        const data = await response.json();

        if (response.ok) {
            authToken = data.token;
            currentUser = data.user;
            
            // Save for persistence
            localStorage.setItem('authToken', authToken);
            localStorage.setItem('currentUser', JSON.stringify(currentUser));
            
            messageDiv.innerHTML = '<div class="message success">Login successful!</div>';
            
            // Show main app
            setTimeout(() => {
                document.getElementById('auth-section').style.display = 'none';
                document.getElementById('app-section').style.display = 'block';
                document.getElementById('user-name').textContent = currentUser.full_name || currentUser.username;
                // Load bookings
                loadMyBookings();
            }, 1000);
        } else {
            messageDiv.innerHTML = `<div class="message error">${data.error || 'Login failed'}</div>`;
        }
    } catch (error) {
        messageDiv.innerHTML = '<div class="message error">Network error</div>';
    }
}

async function register() {
    const fullname = document.getElementById('reg-fullname').value;
    const username = document.getElementById('reg-username').value;
    const email = document.getElementById('reg-email').value;
    const password = document.getElementById('reg-password').value;
    const phone = document.getElementById('reg-phone').value;
    const messageDiv = document.getElementById('register-message');

    if (!username || !email || !password) {
        messageDiv.innerHTML = '<div class="message error">Username, email, password required</div>';
        return;
    }

    messageDiv.innerHTML = '<div class="message">Creating account...</div>';

    try {
        const response = await fetch('http://localhost:3000/api/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, email, password, full_name: fullname, phone })
        });

        const data = await response.json();

        if (response.ok) {
            messageDiv.innerHTML = '<div class="message success">Registration successful! Please login.</div>';
            // Clear form
            document.getElementById('reg-fullname').value = '';
            document.getElementById('reg-username').value = '';
            document.getElementById('reg-email').value = '';
            document.getElementById('reg-password').value = '';
            document.getElementById('reg-phone').value = '';
            // Switch to login
            setTimeout(() => {
                showLogin();
            }, 1500);
        } else {
            messageDiv.innerHTML = `<div class="message error">${data.error || 'Registration failed'}</div>`;
        }
    } catch (error) {
        messageDiv.innerHTML = '<div class="message error">Network error</div>';
    }
}

function logout() {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('authToken');
    localStorage.removeItem('currentUser');
    
    document.getElementById('app-section').style.display = 'none';
    document.getElementById('auth-section').style.display = 'flex';
    
    // Clear login fields
    document.getElementById('login-username').value = '';
    document.getElementById('login-password').value = '';
    document.getElementById('login-message').innerHTML = '';
}

function showRegister() {
    document.getElementById('login-box').style.display = 'none';
    document.getElementById('register-box').style.display = 'block';
}

function showLogin() {
    document.getElementById('login-box').style.display = 'block';
    document.getElementById('register-box').style.display = 'none';
    document.getElementById('register-message').innerHTML = '';
}

function checkExistingLogin() {
    const savedToken = localStorage.getItem('authToken');
    const savedUser = localStorage.getItem('currentUser');
    
    if (savedToken && savedUser) {
        authToken = savedToken;
        currentUser = JSON.parse(savedUser);
        document.getElementById('auth-section').style.display = 'none';
        document.getElementById('app-section').style.display = 'block';
        document.getElementById('user-name').textContent = currentUser.full_name || currentUser.username;
        loadMyBookings();
        return true;
    }
    return false;
}

// ========== searchTrains (uses auth token) ==========
async function searchTrains() {
    const source = document.getElementById('source').value;
    const destination = document.getElementById('destination').value;
    const resultsDiv = document.getElementById('results');

    if (!source || !destination) {
        resultsDiv.innerHTML = '<p style="color:red">Please enter source and destination</p>';
        return;
    }

    resultsDiv.innerHTML = '<p>Searching...</p>';

    try {
        // Use the protected search endpoint with auth token
        const response = await fetch(
            `http://localhost:3000/api/trains/search?source=${encodeURIComponent(source)}&destination=${encodeURIComponent(destination)}`,
            {
                headers: {
                    'Authorization': `Bearer ${authToken}`
                }
            }
        );

        if (response.status === 401 || response.status === 403) {
            logout();
            alert('Session expired. Please login again.');
            return;
        }

        const data = await response.json();

        if (data.error) {
            resultsDiv.innerHTML = `<p style="color:red">${data.error}</p>`;
            return;
        }

        if (data.length === 0) {
            resultsDiv.innerHTML = '<p>No trains found for this route.</p>';
            return;
        }

        // Display results 
        let html = "";
        data.forEach(train => {
            html += `
                <div>
                    <h3>${train.train_name}</h3>
                    <button onclick="book(${train.train_id})">Book</button>
                </div>
            `;
        });
        resultsDiv.innerHTML = html;

    } catch (error) {
        resultsDiv.innerHTML = '<p style="color:red">Network error. Please try again.</p>';
    }
}

// ========== book function (also uses auth token) ==========
async function book(train_id) {
    const seats = prompt("How many seats?", "1");
    if (!seats || seats < 1) return;

    try {
        const response = await fetch('http://localhost:3000/api/book', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify({ train_id, seats: parseInt(seats) })
        });

        if (response.status === 401 || response.status === 403) {
            logout();
            alert('Session expired. Please login again.');
            return;
        }

        const data = await response.json();

        if (response.ok) {
            alert(`Booking Successful! PNR: ${data.pnr}`);
            // Refresh bookings list
            loadMyBookings();
            // Optional: refresh search results
            searchTrains();
        } else {
            alert(`Booking failed: ${data.error}`);
        }
    } catch (error) {
        alert('Network error. Please try again.');
    }
}

// ========== Load user's bookings ==========
async function loadMyBookings() {
    const bookingsDiv = document.getElementById('my-bookings');
    bookingsDiv.innerHTML = '<p>Loading your bookings...</p>';

    try {
        const response = await fetch('http://localhost:3000/api/bookings', {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });

        if (response.status === 401 || response.status === 403) {
            logout();
            return;
        }

        const data = await response.json();

        if (data.length === 0) {
            bookingsDiv.innerHTML = '<p>You have no bookings yet.</p>';
            return;
        }

        let html = '';
        data.forEach(booking => {
            html += `
                <div class="booking-item">
                    <p><strong>${booking.train_name}</strong> (${booking.train_number})</p>
                    <p class="pnr">PNR: ${booking.pnr_number}</p>
                    <p>Seats: ${booking.seats_booked} | Date: ${new Date(booking.travel_date).toLocaleDateString()}</p>
                    <p>Status: ${booking.status}</p>
                </div>
            `;
        });
        bookingsDiv.innerHTML = html;

    } catch (error) {
        bookingsDiv.innerHTML = '<p style="color:red">Error loading bookings</p>';
    }
}

// ========== INITIALIZATION ==========
// Check if user is already logged in
if (!checkExistingLogin()) {
    // Show login form
    document.getElementById('auth-section').style.display = 'flex';
    document.getElementById('app-section').style.display = 'none';
}
