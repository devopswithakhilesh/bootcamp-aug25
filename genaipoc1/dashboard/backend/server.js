const express = require('express');
const cors = require('cors');
const path = require('path');
const { Pool } = require('pg');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3001;

// Database configuration
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'failuredb',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  port: 5432,
});

// Java app URL
const JAVA_APP_URL = process.env.JAVA_APP_URL || 'http://localhost:8080';

// Ollama URL
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';

// Qdrant URL
const QDRANT_URL = process.env.QDRANT_URL || 'http://localhost:6333';

// Collection name for RAG documents
const COLLECTION_NAME = 'knowledge_base';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Health endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Get current application status
app.get('/api/status', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM app_status WHERE id = 1'
    );

    if (result.rows.length === 0) {
      return res.json({
        current_status: 'unknown',
        last_check_time: null,
        failure_count: 0
      });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching status:', error);
    res.status(500).json({ error: 'Failed to fetch status' });
  }
});

// Get health check history
app.get('/api/health-checks', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const result = await pool.query(
      'SELECT * FROM health_checks ORDER BY timestamp DESC LIMIT $1',
      [limit]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching health checks:', error);
    res.status(500).json({ error: 'Failed to fetch health checks' });
  }
});

// Get latest health check
app.get('/api/health-checks/latest', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM health_checks ORDER BY timestamp DESC LIMIT 1'
    );

    if (result.rows.length === 0) {
      return res.json(null);
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching latest health check:', error);
    res.status(500).json({ error: 'Failed to fetch latest health check' });
  }
});

// Trigger failure on Java app
app.post('/api/trigger-failure/:type', async (req, res) => {
  const { type } = req.params;

  try {
    const response = await axios.post(
      `${JAVA_APP_URL}/api/failure/trigger/${type}`
    );

    res.json(response.data);
  } catch (error) {
    console.error('Error triggering failure:', error.message);
    res.status(500).json({
      error: 'Failed to trigger failure',
      details: error.message
    });
  }
});

// Clear failure on Java app
app.post('/api/clear-failure/:type', async (req, res) => {
  const { type } = req.params;

  try {
    const response = await axios.post(
      `${JAVA_APP_URL}/api/failure/clear/${type}`
    );

    res.json(response.data);
  } catch (error) {
    console.error('Error clearing failure:', error.message);
    res.status(500).json({
      error: 'Failed to clear failure',
      details: error.message
    });
  }
});

// Clear all failures
app.post('/api/clear-all-failures', async (req, res) => {
  try {
    const response = await axios.post(
      `${JAVA_APP_URL}/api/failure/clear-all`
    );

    res.json(response.data);
  } catch (error) {
    console.error('Error clearing all failures:', error.message);
    res.status(500).json({
      error: 'Failed to clear all failures',
      details: error.message
    });
  }
});

// Get failure status from Java app
app.get('/api/failure-status', async (req, res) => {
  try {
    const response = await axios.get(
      `${JAVA_APP_URL}/api/failure/status`
    );

    res.json(response.data);
  } catch (error) {
    console.error('Error fetching failure status:', error.message);
    res.status(500).json({
      error: 'Failed to fetch failure status',
      details: error.message
    });
  }
});

// ==================== RAG System ====================

// Initialize Qdrant collection
async function initializeQdrant() {
  try {
    // Check if collection exists
    const collections = await axios.get(`${QDRANT_URL}/collections`);
    const exists = collections.data.result.collections.some(c => c.name === COLLECTION_NAME);

    if (!exists) {
      // Create collection with embedding dimension 768 (nomic-embed-text)
      await axios.put(`${QDRANT_URL}/collections/${COLLECTION_NAME}`, {
        vectors: {
          size: 768,
          distance: 'Cosine'
        }
      });
      console.log(`Created Qdrant collection: ${COLLECTION_NAME}`);
    } else {
      console.log(`Qdrant collection ${COLLECTION_NAME} already exists`);
    }
  } catch (error) {
    console.error('Error initializing Qdrant:', error.message);
  }
}

// Initialize on startup
initializeQdrant();

// Generate embeddings using Ollama
async function generateEmbedding(text) {
  try {
    const response = await axios.post(
      `${OLLAMA_URL}/api/embeddings`,
      {
        model: 'nomic-embed-text',
        prompt: text
      },
      { timeout: 30000 }
    );
    return response.data.embedding;
  } catch (error) {
    console.error('Error generating embedding:', error.message);
    throw error;
  }
}

// Search for relevant documents
async function searchDocuments(query, limit = 3) {
  try {
    const embedding = await generateEmbedding(query);

    const response = await axios.post(
      `${QDRANT_URL}/collections/${COLLECTION_NAME}/points/search`,
      {
        vector: embedding,
        limit: limit,
        with_payload: true
      }
    );

    return response.data.result || [];
  } catch (error) {
    console.error('Error searching documents:', error.message);
    return [];
  }
}

// Upload document
app.post('/api/documents/upload', async (req, res) => {
  const { content, title, metadata } = req.body;

  if (!content) {
    return res.status(400).json({ error: 'Content is required' });
  }

  try {
    // Split content into chunks (simple chunking by paragraphs)
    const chunks = content.split('\n\n').filter(chunk => chunk.trim().length > 20);

    let uploadedChunks = 0;
    const points = [];

    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i].trim();

      // Generate embedding
      const embedding = await generateEmbedding(chunk);

      // Create point for Qdrant
      const point = {
        id: Date.now() + i, // Simple ID generation
        vector: embedding,
        payload: {
          content: chunk,
          title: title || 'Untitled Document',
          chunk_index: i,
          total_chunks: chunks.length,
          ...metadata
        }
      };

      points.push(point);
      uploadedChunks++;
    }

    // Upload to Qdrant
    await axios.put(
      `${QDRANT_URL}/collections/${COLLECTION_NAME}/points`,
      { points: points }
    );

    res.json({
      success: true,
      message: `Document uploaded successfully`,
      chunks_uploaded: uploadedChunks,
      title: title || 'Untitled Document'
    });
  } catch (error) {
    console.error('Error uploading document:', error.message);
    res.status(500).json({
      error: 'Failed to upload document',
      details: error.message
    });
  }
});

// List documents
app.get('/api/documents', async (req, res) => {
  try {
    const response = await axios.post(
      `${QDRANT_URL}/collections/${COLLECTION_NAME}/points/scroll`,
      {
        limit: 100,
        with_payload: true,
        with_vector: false
      }
    );

    // Group by title
    const documents = {};
    response.data.result.points.forEach(point => {
      const title = point.payload.title;
      if (!documents[title]) {
        documents[title] = {
          title: title,
          chunks: 0,
          first_chunk: point.payload.content.substring(0, 100) + '...'
        };
      }
      documents[title].chunks++;
    });

    res.json({
      documents: Object.values(documents),
      total: Object.keys(documents).length
    });
  } catch (error) {
    console.error('Error listing documents:', error.message);
    res.status(500).json({
      error: 'Failed to list documents',
      details: error.message
    });
  }
});

// Delete all documents
app.delete('/api/documents/all', async (req, res) => {
  try {
    // Delete and recreate collection
    await axios.delete(`${QDRANT_URL}/collections/${COLLECTION_NAME}`);
    await initializeQdrant();

    res.json({
      success: true,
      message: 'All documents deleted'
    });
  } catch (error) {
    console.error('Error deleting documents:', error.message);
    res.status(500).json({
      error: 'Failed to delete documents',
      details: error.message
    });
  }
});

// Chat with AI (RAG-enabled)
app.post('/api/chat', async (req, res) => {
  const { message, history } = req.body;

  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }

  try {
    // Search for relevant documents
    const relevantDocs = await searchDocuments(message, 3);

    console.log(`Query: "${message}"`);
    console.log(`Retrieved ${relevantDocs.length} documents`);
    if (relevantDocs.length > 0) {
      console.log('Retrieved documents:', relevantDocs.map((d, i) => ({
        index: i,
        title: d.payload.title,
        content: d.payload.content.substring(0, 100) + '...'
      })));
    }

    // Build context from conversation history
    let prompt = 'Assistant: Hello! I\'m your local AI assistant (Gemma 2B). I\'m running entirely on your computer - no data leaves your machine. I can answer questions about the failure monitoring system, technical topics, and any other questions you have.\n\n';

    // Add retrieved documents as context (RAG)
    if (relevantDocs && relevantDocs.length > 0) {
      prompt += 'Here is some relevant information from the knowledge base that may help answer the question:\n\n';
      relevantDocs.forEach((doc, index) => {
        prompt += `${doc.payload.content}\n\n`;
      });
      prompt += 'Use this information if it\'s relevant to the question. If the information above doesn\'t fully answer the question, feel free to use your general knowledge as well.\n\n';
    }

    // Add conversation history
    if (history && history.length > 0) {
      history.forEach(msg => {
        prompt += `${msg.role === 'user' ? 'User' : 'Assistant'}: ${msg.content}\n`;
      });
    }

    // Add current message
    prompt += `User: ${message}\nAssistant:`;

    console.log('=== FULL PROMPT ===');
    console.log(prompt);
    console.log('=== END PROMPT ===');

    const response = await axios.post(
      `${OLLAMA_URL}/api/generate`,
      {
        model: 'gemma:2b',
        prompt: prompt,
        stream: false
      },
      { timeout: 60000 }
    );

    if (response.status === 200) {
      const aiResponse = response.data.response || 'Sorry, I could not generate a response.';
      res.json({
        response: aiResponse.trim(),
        model: 'gemma:2b (local)',
        rag_enabled: relevantDocs.length > 0,
        sources_used: relevantDocs.length
      });
    } else {
      res.status(500).json({ error: 'AI service unavailable' });
    }
  } catch (error) {
    console.error('Error chatting with AI:', error.message);
    res.status(500).json({
      error: 'Failed to get AI response',
      details: error.message
    });
  }
});

// Serve React app for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
app.listen(PORT, () => {
  console.log(`Dashboard backend running on port ${PORT}`);
});
