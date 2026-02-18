-- Users and Authentication
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE user_profiles (
    profile_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    profile_picture VARCHAR(255),
    phone_number VARCHAR(20),
    account_status ENUM('active','suspended','deactivated') DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Roles and Permissions
CREATE TABLE roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name ENUM('Admin','Organizer','Coach','Referee','Player') UNIQUE NOT NULL
);

CREATE TABLE user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE role_applications (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    reviewed_at DATETIME,
    admin_id INT,
    admin_notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id),
    FOREIGN KEY (admin_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Admin and System
CREATE TABLE system_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    setting_name VARCHAR(255) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    description TEXT,
    updated_by INT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Tournaments and Teams
CREATE TABLE tournaments (
    tournament_id INT AUTO_INCREMENT PRIMARY KEY,
    organizer_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    division VARCHAR(100),
    age_group VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_start DATE NOT NULL,
    registration_end DATE NOT NULL,
    venue VARCHAR(255),
    location VARCHAR(255),
    status ENUM('upcoming','ongoing','completed') DEFAULT 'upcoming',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (organizer_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE teams (
    team_id INT AUTO_INCREMENT PRIMARY KEY,
    coach_id INT NOT NULL,
    team_name VARCHAR(255) NOT NULL,
    logo VARCHAR(255),
    village VARCHAR(100),
    division VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (coach_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE players (
    player_id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    user_id INT,
    full_name VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    position VARCHAR(50),
    jersey_number INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE TABLE tournament_enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    tournament_id INT NOT NULL,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    submission_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    decision_date DATETIME,
    organizer_notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_enrollment (team_id, tournament_id),
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE,
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id) ON DELETE CASCADE
);

-- Matches and Match Events
CREATE TABLE matches (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    home_team INT NOT NULL,
    away_team INT NOT NULL,
    match_date DATE NOT NULL,
    match_time TIME,
    venue VARCHAR(255),
    home_team_score INT DEFAULT 0,
    away_team_score INT DEFAULT 0,
    status ENUM('scheduled','played','disputed','confirmed') DEFAULT 'scheduled',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_match_schedule (tournament_id, match_date, home_team, away_team),
    CHECK (home_team != away_team),
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    FOREIGN KEY (home_team) REFERENCES teams(team_id) ON DELETE CASCADE,
    FOREIGN KEY (away_team) REFERENCES teams(team_id) ON DELETE CASCADE
);

CREATE TABLE match_referees (
    match_id INT NOT NULL,
    referee_id INT NOT NULL,
    assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (match_id, referee_id),
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    FOREIGN KEY (referee_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE match_events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    event_type ENUM('goal','yellow_card','red_card') NOT NULL,
    minute INT NOT NULL,
    player_id INT,
    team_id INT NOT NULL,
    submitted_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE SET NULL,
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE,
    FOREIGN KEY (submitted_by) REFERENCES users(user_id)
);

CREATE TABLE match_confirmations (
    confirmation_id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    home_coach_id INT NOT NULL,
    away_coach_id INT NOT NULL,
    home_team_confirmed ENUM('pending','confirmed','disputed') DEFAULT 'pending',
    away_team_confirmed ENUM('pending','confirmed','disputed') DEFAULT 'pending',
    home_coach_confirmed_at DATETIME,
    away_coach_confirmed_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_match_confirmation (match_id),
    FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE,
    FOREIGN KEY (home_coach_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (away_coach_id) REFERENCES users(user_id) ON DELETE CASCADE
);

 is the database good or need any changes for it