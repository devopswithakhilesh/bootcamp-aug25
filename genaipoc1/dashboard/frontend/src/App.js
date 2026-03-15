import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Chat from './Chat';
import Documents from './Documents';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || '';

function App() {
  const [currentView, setCurrentView] = useState('monitoring');
  const [status, setStatus] = useState(null);
  const [latestCheck, setLatestCheck] = useState(null);
  const [healthHistory, setHealthHistory] = useState([]);
  const [failureStatus, setFailureStatus] = useState(null);
  const [loading, setLoading] = useState(false);

  const failureTypes = [
    { id: 'http_500', label: 'HTTP 500 Error' },
    { id: 'http_503', label: 'HTTP 503 Service Unavailable' },
    { id: 'timeout', label: 'Timeout' },
    { id: 'exception', label: 'Exception' },
    { id: 'memory_leak', label: 'Memory Leak' },
    { id: 'cpu_spike', label: 'CPU Spike' }
  ];

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 10000); // Refresh every 10 seconds
    return () => clearInterval(interval);
  }, []);

  const fetchData = async () => {
    try {
      const [statusRes, latestRes, historyRes, failureRes] = await Promise.all([
        axios.get(`${API_URL}/api/status`),
        axios.get(`${API_URL}/api/health-checks/latest`),
        axios.get(`${API_URL}/api/health-checks?limit=10`),
        axios.get(`${API_URL}/api/failure-status`)
      ]);

      setStatus(statusRes.data);
      setLatestCheck(latestRes.data);
      setHealthHistory(historyRes.data);
      setFailureStatus(failureRes.data);
    } catch (error) {
      console.error('Error fetching data:', error);
    }
  };

  const triggerFailure = async (type) => {
    setLoading(true);
    try {
      await axios.post(`${API_URL}/api/trigger-failure/${type}`);
      alert(`${type} failure triggered successfully`);
      fetchData();
    } catch (error) {
      alert(`Failed to trigger ${type}: ${error.message}`);
    }
    setLoading(false);
  };

  const clearFailure = async (type) => {
    setLoading(true);
    try {
      await axios.post(`${API_URL}/api/clear-failure/${type}`);
      alert(`${type} failure cleared successfully`);
      fetchData();
    } catch (error) {
      alert(`Failed to clear ${type}: ${error.message}`);
    }
    setLoading(false);
  };

  const clearAllFailures = async () => {
    setLoading(true);
    try {
      await axios.post(`${API_URL}/api/clear-all-failures`);
      alert('All failures cleared successfully');
      fetchData();
    } catch (error) {
      alert(`Failed to clear all failures: ${error.message}`);
    }
    setLoading(false);
  };

  const formatTimestamp = (timestamp) => {
    if (!timestamp) return 'N/A';
    return new Date(timestamp).toLocaleString();
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Failure Monitoring Dashboard</h1>
        <div className="nav-tabs">
          <button
            className={`nav-tab ${currentView === 'monitoring' ? 'active' : ''}`}
            onClick={() => setCurrentView('monitoring')}
          >
            📊 Monitoring
          </button>
          <button
            className={`nav-tab ${currentView === 'chat' ? 'active' : ''}`}
            onClick={() => setCurrentView('chat')}
          >
            💬 AI Chat
          </button>
          <button
            className={`nav-tab ${currentView === 'documents' ? 'active' : ''}`}
            onClick={() => setCurrentView('documents')}
          >
            📚 Knowledge Base
          </button>
        </div>
      </header>

      {currentView === 'chat' && <Chat />}

      {currentView === 'documents' && <Documents />}

      {currentView === 'monitoring' && (
      <div className="container">
        {/* Current Status */}
        <div className="card">
          <h2>Current Status</h2>
          {status ? (
            <div>
              <div className={`status-badge ${status.current_status}`}>
                {status.current_status ? status.current_status.toUpperCase() : 'UNKNOWN'}
              </div>
              <p>Last Check: {formatTimestamp(status.last_check_time)}</p>
              <p>Total Failures: {status.failure_count || 0}</p>
            </div>
          ) : (
            <p>Loading...</p>
          )}
        </div>

        {/* Latest Health Check */}
        {latestCheck && latestCheck.status === 'unhealthy' && (
          <div className="card alert">
            <h2>Latest Error</h2>
            <div className="error-summary">
              {latestCheck.error_summary}
            </div>
            <p className="timestamp">{formatTimestamp(latestCheck.timestamp)}</p>
          </div>
        )}

        {/* Failure Controls */}
        <div className="card">
          <h2>Failure Controls</h2>
          <div className="button-grid">
            {failureTypes.map(failure => (
              <div key={failure.id} className="failure-control">
                <span className="failure-label">{failure.label}</span>
                <div className="button-group">
                  <button
                    onClick={() => triggerFailure(failure.id)}
                    disabled={loading || (failureStatus?.failures?.[failure.id])}
                    className="btn btn-trigger"
                  >
                    Trigger
                  </button>
                  <button
                    onClick={() => clearFailure(failure.id)}
                    disabled={loading || !(failureStatus?.failures?.[failure.id])}
                    className="btn btn-clear"
                  >
                    Clear
                  </button>
                </div>
                {failureStatus?.failures?.[failure.id] && (
                  <span className="active-indicator">ACTIVE</span>
                )}
              </div>
            ))}
          </div>
          <button
            onClick={clearAllFailures}
            disabled={loading}
            className="btn btn-clear-all"
          >
            Clear All Failures
          </button>
        </div>

        {/* Health Check History */}
        <div className="card">
          <h2>Health Check History</h2>
          <div className="table-container">
            <table>
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>Status</th>
                  <th>Summary</th>
                </tr>
              </thead>
              <tbody>
                {healthHistory.map((check, index) => (
                  <tr key={index} className={check.status}>
                    <td>{formatTimestamp(check.timestamp)}</td>
                    <td>
                      <span className={`status-badge ${check.status}`}>
                        {check.status.toUpperCase()}
                      </span>
                    </td>
                    <td className="summary-cell">{check.error_summary}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
      )}
    </div>
  );
}

export default App;
