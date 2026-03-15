-- Create the health_checks table
CREATE TABLE IF NOT EXISTS health_checks (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL,
    error_summary TEXT,
    raw_logs TEXT
);

-- Create the app_status table
CREATE TABLE IF NOT EXISTS app_status (
    id INTEGER PRIMARY KEY DEFAULT 1,
    current_status VARCHAR(20) NOT NULL DEFAULT 'unknown',
    last_check_time TIMESTAMP,
    failure_count INTEGER DEFAULT 0,
    CONSTRAINT single_row CHECK (id = 1)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_health_checks_timestamp ON health_checks(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_health_checks_status ON health_checks(status);

-- Insert initial app_status row
INSERT INTO app_status (id, current_status, last_check_time, failure_count)
VALUES (1, 'unknown', NULL, 0)
ON CONFLICT (id) DO NOTHING;
