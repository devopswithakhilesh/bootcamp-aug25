import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Documents.css';

const API_URL = process.env.REACT_APP_API_URL || '';

function Documents() {
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [uploadForm, setUploadForm] = useState({
    title: '',
    content: ''
  });
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    fetchDocuments();
  }, []);

  const fetchDocuments = async () => {
    setLoading(true);
    try {
      const response = await axios.get(`${API_URL}/api/documents`);
      setDocuments(response.data.documents || []);
    } catch (error) {
      console.error('Error fetching documents:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setUploadForm(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (event) => {
      setUploadForm(prev => ({
        ...prev,
        content: event.target.result,
        title: prev.title || file.name
      }));
    };
    reader.readAsText(file);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!uploadForm.content.trim()) {
      alert('Please add content or upload a file');
      return;
    }

    setUploading(true);
    try {
      const response = await axios.post(`${API_URL}/api/documents/upload`, {
        title: uploadForm.title || 'Untitled Document',
        content: uploadForm.content,
        metadata: {
          uploaded_at: new Date().toISOString()
        }
      });

      alert(response.data.message);
      setUploadForm({ title: '', content: '' });
      fetchDocuments();
    } catch (error) {
      alert(`Failed to upload: ${error.response?.data?.error || error.message}`);
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteAll = async () => {
    if (!window.confirm('Are you sure you want to delete ALL documents? This cannot be undone.')) {
      return;
    }

    setLoading(true);
    try {
      await axios.delete(`${API_URL}/api/documents/all`);
      alert('All documents deleted successfully');
      fetchDocuments();
    } catch (error) {
      alert(`Failed to delete: ${error.response?.data?.error || error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="documents-container">
      <div className="documents-header">
        <div>
          <h2>Knowledge Base</h2>
          <p className="documents-subtitle">Upload documents for AI to reference in chat</p>
        </div>
      </div>

      <div className="documents-content">
        {/* Upload Section */}
        <div className="card upload-section">
          <h3>Upload Document</h3>
          <form onSubmit={handleSubmit} className="upload-form">
            <div className="form-group">
              <label htmlFor="title">Document Title</label>
              <input
                type="text"
                id="title"
                name="title"
                value={uploadForm.title}
                onChange={handleInputChange}
                placeholder="e.g., API Documentation, Runbook, Error Guide"
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label htmlFor="file">Upload File (txt, md, or paste below)</label>
              <input
                type="file"
                id="file"
                accept=".txt,.md,.markdown"
                onChange={handleFileUpload}
                className="form-input file-input"
              />
            </div>

            <div className="form-group">
              <label htmlFor="content">Document Content</label>
              <textarea
                id="content"
                name="content"
                value={uploadForm.content}
                onChange={handleInputChange}
                placeholder="Paste your documentation here or upload a file above..."
                rows="12"
                className="form-textarea"
              />
              <div className="content-info">
                {uploadForm.content.length} characters
              </div>
            </div>

            <button
              type="submit"
              disabled={uploading || !uploadForm.content.trim()}
              className="btn btn-upload"
            >
              {uploading ? 'Uploading...' : 'Upload Document'}
            </button>
          </form>
        </div>

        {/* Documents List */}
        <div className="card documents-list-section">
          <div className="list-header">
            <h3>Uploaded Documents ({documents.length})</h3>
            {documents.length > 0 && (
              <button onClick={handleDeleteAll} className="btn btn-delete-all">
                Delete All
              </button>
            )}
          </div>

          {loading ? (
            <p className="loading-text">Loading documents...</p>
          ) : documents.length === 0 ? (
            <div className="empty-state">
              <p>No documents uploaded yet</p>
              <p className="empty-hint">Upload your first document to enable RAG-powered chat!</p>
            </div>
          ) : (
            <div className="documents-list">
              {documents.map((doc, index) => (
                <div key={index} className="document-item">
                  <div className="document-icon">📄</div>
                  <div className="document-info">
                    <h4>{doc.title}</h4>
                    <p className="document-preview">{doc.first_chunk}</p>
                    <p className="document-meta">{doc.chunks} chunks</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="documents-footer">
        <div className="info-box">
          <h4>How RAG Works:</h4>
          <ol>
            <li>📤 Upload your documentation (APIs, runbooks, guides)</li>
            <li>🔍 When you ask a question, AI searches your documents</li>
            <li>🤖 AI uses relevant context to answer accurately</li>
            <li>✅ Get answers specific to YOUR system and docs</li>
          </ol>
        </div>

        <div className="info-box">
          <h4>Supported Content:</h4>
          <ul>
            <li>✓ API documentation</li>
            <li>✓ Error troubleshooting guides</li>
            <li>✓ System runbooks and procedures</li>
            <li>✓ Architecture documents</li>
            <li>✓ Configuration guides</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default Documents;
