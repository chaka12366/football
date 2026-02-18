<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../core/database.php';

$response = array();

// Handle requests
$action = $_POST['action'] ?? $_GET['action'] ?? '';

if ($action === 'login') {
    handleLogin($conn, $response);
} elseif ($action === 'signup') {
    handleSignup($conn, $response);
} else {
    $response['error'] = true;
    $response['message'] = 'Invalid action';
}

echo json_encode($response);
mysqli_close($conn);

/**
 * Handle Login
 */
function handleLogin($conn, &$response) {
    $email = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');
    $rememberMe = $_POST['rememberMe'] ?? false;

    // Validation
    if (empty($email) || empty($password)) {
        $response['error'] = true;
        $response['message'] = 'Email and password are required';
        return;
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $response['error'] = true;
        $response['message'] = 'Invalid email format';
        return;
    }

    // Check if user exists
    $stmt = $conn->prepare("SELECT user_id, password_hash FROM users WHERE email = ?");
    if (!$stmt) {
        $response['error'] = true;
        $response['message'] = 'Database error: ' . $conn->error;
        return;
    }

    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        $response['error'] = true;
        $response['message'] = 'Email or password is incorrect';
        return;
    }

    $user = $result->fetch_assoc();
    $stmt->close();

    // Verify password
    if (!password_verify($password, $user['password_hash'])) {
        $response['error'] = true;
        $response['message'] = 'Email or password is incorrect';
        return;
    }

    // Update last login
    $updateStmt = $conn->prepare("UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = ?");
    $updateStmt->bind_param("i", $user['user_id']);
    $updateStmt->execute();
    $updateStmt->close();

    // Set session
    session_start();
    $_SESSION['user_id'] = $user['user_id'];
    $_SESSION['email'] = $email;

    // Handle remember me
    if ($rememberMe) {
        $token = bin2hex(random_bytes(32));
        $hashedToken = password_hash($token, PASSWORD_DEFAULT);
        setcookie('remember_token', $token, time() + (30 * 24 * 60 * 60), '/');
        // You can store the hashedToken in database if needed
    }

    $response['error'] = false;
    $response['message'] = 'Login successful';
    $response['user_id'] = $user['user_id'];
    $response['redirect'] = '../../../index.html'; // Redirect to main page
}

/**
 * Handle Signup
 */
function handleSignup($conn, &$response) {
    $email = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');
    $confirmPassword = trim($_POST['confirmPassword'] ?? '');
    $username = trim($_POST['username'] ?? '');

    // Validation
    if (empty($email) || empty($password) || empty($confirmPassword) || empty($username)) {
        $response['error'] = true;
        $response['message'] = 'All fields are required';
        return;
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $response['error'] = true;
        $response['message'] = 'Invalid email format';
        return;
    }

    if (strlen($password) < 6) {
        $response['error'] = true;
        $response['message'] = 'Password must be at least 6 characters';
        return;
    }

    if ($password !== $confirmPassword) {
        $response['error'] = true;
        $response['message'] = 'Passwords do not match';
        return;
    }

    if (strlen($username) < 3) {
        $response['error'] = true;
        $response['message'] = 'Username must be at least 3 characters';
        return;
    }

    // Check if email already exists
    $checkStmt = $conn->prepare("SELECT user_id FROM users WHERE email = ?");
    if (!$checkStmt) {
        $response['error'] = true;
        $response['message'] = 'Database error: ' . $conn->error;
        return;
    }

    $checkStmt->bind_param("s", $email);
    $checkStmt->execute();
    if ($checkStmt->get_result()->num_rows > 0) {
        $response['error'] = true;
        $response['message'] = 'Email already exists';
        $checkStmt->close();
        return;
    }
    $checkStmt->close();

    // Hash password
    $passwordHash = password_hash($password, PASSWORD_BCRYPT);

    // Insert user
    $insertStmt = $conn->prepare("INSERT INTO users (email, password_hash) VALUES (?, ?)");
    if (!$insertStmt) {
        $response['error'] = true;
        $response['message'] = 'Database error: ' . $conn->error;
        return;
    }

    $insertStmt->bind_param("ss", $email, $passwordHash);
    
    if (!$insertStmt->execute()) {
        $response['error'] = true;
        $response['message'] = 'Failed to create account: ' . $insertStmt->error;
        $insertStmt->close();
        return;
    }

    $userId = $insertStmt->insert_id;
    $insertStmt->close();

    // Insert user profile with username as full_name
    $profileStmt = $conn->prepare("INSERT INTO user_profiles (user_id, full_name) VALUES (?, ?)");
    if (!$profileStmt) {
        $response['error'] = true;
        $response['message'] = 'Failed to create profile: ' . $conn->error;
        return;
    }

    $profileStmt->bind_param("is", $userId, $username);
    $profileStmt->execute();
    $profileStmt->close();

    // Set session
    session_start();
    $_SESSION['user_id'] = $userId;
    $_SESSION['email'] = $email;

    $response['error'] = false;
    $response['message'] = 'Account created successfully';
    $response['user_id'] = $userId;
    $response['redirect'] = '../../../index.html';
}
?>
