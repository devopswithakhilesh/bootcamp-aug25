# RAG Implementation Documentation

## Overview

This project implements a **Retrieval-Augmented Generation (RAG)** system that allows the AI chat assistant to access custom knowledge beyond its training data. The RAG system runs entirely locally within the Kubernetes cluster, maintaining 100% privacy.

## What is RAG?

RAG (Retrieval-Augmented Generation) is a technique that enhances AI responses by:
1. **Storing documents** as vector embeddings in a database
2. **Searching** for relevant documents when a user asks a question
3. **Augmenting** the AI prompt with retrieved document context
4. **Generating** responses based on both the question and the retrieved knowledge

This allows the AI to answer questions about information it wasn't originally trained on.

## Architecture

```
┌─────────────────┐
│  User Question  │
└────────┬────────┘
         │
         v
┌─────────────────────────────────────┐
│  Dashboard Backend (Node.js)        │
│  ┌───────────────────────────────┐  │
│  │ 1. Generate question embedding│  │
│  │    (nomic-embed-text)         │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 2. Search Qdrant for similar  │  │
│  │    document chunks            │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 3. Build prompt with context  │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 4. Send to Gemma 2B model     │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
         │
         v
┌─────────────────┐
│  AI Response    │
│  with sources   │
└─────────────────┘
```

## Components

### 1. Qdrant Vector Database

**Location:** `k8s-manifests/06-qdrant.yaml`

Qdrant is a high-performance vector search engine that stores document embeddings.

**Configuration:**
- **Image:** `qdrant/qdrant:latest`
- **Storage:** 1Gi PersistentVolumeClaim
- **Memory:** 512Mi limit
- **Ports:**
  - 6333: REST API
  - 6334: gRPC
- **Collection:** `knowledge_base`
  - Vector dimensions: 768
  - Distance metric: Cosine similarity

**Deployment:**
```bash
kubectl apply -f k8s-manifests/06-qdrant.yaml
```

### 2. Ollama Embedding Model

**Model:** `nomic-embed-text`
- **Size:** 274 MB
- **Dimensions:** 768-dimensional vectors
- **Purpose:** Converts text into semantic vector representations

**Pulling the model:**
```bash
kubectl exec -n failure-monitoring deployment/ollama -- ollama pull nomic-embed-text
```

### 3. Backend API Endpoints

**Location:** `dashboard/backend/server.js`

#### Document Upload: `POST /api/documents/upload`

Uploads and indexes documents into the knowledge base.

**Request:**
```json
{
  "title": "Document Title",
  "content": "Document content here...",
  "metadata": {
    "source": "user_upload",
    "uploaded_at": "2024-01-01T00:00:00.000Z"
  }
}
```

**Process:**
1. Splits content into chunks (paragraphs with 20+ characters)
2. Generates embeddings for each chunk using `nomic-embed-text`
3. Stores vectors in Qdrant with metadata

**Response:**
```json
{
  "message": "Document uploaded successfully",
  "chunks": 15,
  "document_id": "unique-doc-id"
}
```

#### List Documents: `GET /api/documents`

Returns all documents in the knowledge base.

**Response:**
```json
{
  "documents": [
    {
      "id": "doc-id",
      "title": "Document Title",
      "chunks": 15,
      "uploaded_at": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

#### Delete All Documents: `DELETE /api/documents/all`

Clears the entire knowledge base.

**Response:**
```json
{
  "message": "All documents deleted successfully"
}
```

#### Chat with RAG: `POST /api/chat`

Processes chat messages with RAG enhancement.

**Request:**
```json
{
  "message": "What is the deployment process?",
  "history": [
    {"role": "user", "content": "Previous message"},
    {"role": "assistant", "content": "Previous response"}
  ]
}
```

**Process:**
1. Generates embedding for the user's question
2. Searches Qdrant for top 3 similar document chunks
3. Builds prompt with retrieved context:
   ```
   Context from knowledge base:
   [Document 1]: Relevant content here...
   [Document 2]: More relevant content...
   ---

   Conversation history:
   User: Previous message
   Assistant: Previous response

   User: What is the deployment process?
   ```
4. Sends enhanced prompt to Gemma 2B
5. Returns response with RAG metadata

**Response:**
```json
{
  "response": "Based on the deployment documentation...",
  "model": "gemma:2b (local)",
  "rag_enabled": true,
  "sources_used": 3
}
```

### 4. Frontend Components

#### Knowledge Base Tab

**Location:** `dashboard/frontend/src/Documents.js`

Features:
- **File Upload:** Upload .txt, .md files
- **Text Input:** Paste content directly
- **Document List:** View uploaded documents with previews
- **Chunk Count:** Shows how many chunks each document was split into
- **Delete All:** Clear entire knowledge base

**Usage:**
1. Navigate to "Knowledge Base" tab
2. Enter document title
3. Paste content or upload file
4. Click "Upload to Knowledge Base"
5. Documents appear in the list below

#### Chat Interface with RAG Indicators

**Location:** `dashboard/frontend/src/Chat.js`

When RAG is used, messages display:
```
📚 Used 3 documents from knowledge base
```

This indicator appears when:
- `rag_enabled` is `true`
- `sources_used` > 0

## How to Use

### 1. Access the Dashboard

```bash
minikube service dashboard-service -n failure-monitoring
```

### 2. Upload Knowledge Documents

Navigate to the **Knowledge Base** tab.

**Example Document:**
```
Title: Deployment Process

Content:
The deployment process involves the following steps:

1. Build Docker images using eval $(minikube docker-env)
2. Apply Kubernetes manifests with kubectl apply -f k8s-manifests/
3. Wait for pods to be ready
4. Pull Ollama models (gemma:2b and nomic-embed-text)
5. Access the dashboard via minikube service

For troubleshooting, check pod logs with kubectl logs.
```

### 3. Ask Questions in Chat

Navigate to the **AI Chat** tab.

**Example Questions:**
- "How do I deploy this application?"
- "What are the steps for troubleshooting?"
- "Explain the deployment process"

The AI will use the uploaded documents to provide accurate answers.

### 4. Verify RAG is Working

Look for the indicator:
```
📚 Used N document(s) from knowledge base
```

This confirms the AI retrieved relevant context from your uploaded documents.

## Technical Details

### Document Chunking Strategy

**Code:** `dashboard/backend/server.js:219-222`

```javascript
const chunks = content.split('\n\n').filter(chunk => chunk.trim().length > 20);
```

Documents are split by double newlines (paragraphs) and chunks smaller than 20 characters are discarded.

**Why this approach?**
- Maintains semantic coherence (complete thoughts)
- Avoids tiny, meaningless chunks
- Works well for markdown and text files

### Embedding Generation

**Code:** `dashboard/backend/server.js:35-45`

```javascript
async function generateEmbedding(text) {
  try {
    const response = await axios.post(`${OLLAMA_URL}/api/embeddings`, {
      model: 'nomic-embed-text',
      prompt: text
    });
    return response.data.embedding;
  } catch (error) {
    console.error('Error generating embedding:', error);
    throw error;
  }
}
```

Each chunk is converted to a 768-dimensional vector that captures semantic meaning.

### Vector Search

**Code:** `dashboard/backend/server.js:48-63`

```javascript
async function searchDocuments(query, limit = 3) {
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
}
```

**Process:**
1. Convert user question to embedding
2. Search Qdrant for vectors with highest cosine similarity
3. Return top N most relevant chunks with metadata

### Context Injection

**Code:** `dashboard/backend/server.js:266-272`

```javascript
if (relevantDocs && relevantDocs.length > 0) {
  prompt += '\n\nContext from knowledge base:\n';
  relevantDocs.forEach((doc, index) => {
    prompt += `[Document ${index + 1}]: ${doc.payload.content}\n\n`;
  });
  prompt += '---\n\n';
}
```

Retrieved documents are prepended to the prompt before sending to the AI model.

## Performance Characteristics

### Resource Usage

**Qdrant:**
- Memory: ~100-200 MB (base) + vectors
- CPU: Minimal (only during searches)
- Storage: ~1 KB per document chunk

**nomic-embed-text model:**
- Memory: ~300-400 MB when loaded
- Processing: ~100-200ms per embedding

**Total RAG overhead:**
- Memory: ~400-600 MB
- Latency: +200-500ms per chat request

### Scaling

**Current Configuration:**
- Collection: `knowledge_base`
- Max documents: Limited by storage (1Gi PVC)
- Estimated capacity: ~50,000-100,000 chunks

**To increase capacity:**
1. Increase PVC size in `06-qdrant.yaml`
2. Increase Qdrant memory limits
3. Consider multiple collections for different domains

## Troubleshooting

### RAG not working (no source indicator)

**Check Qdrant:**
```bash
kubectl logs -n failure-monitoring deployment/qdrant
kubectl get pods -n failure-monitoring | grep qdrant
```

**Check collection:**
```bash
kubectl exec -n failure-monitoring deployment/qdrant -- wget -qO- http://localhost:6333/collections/knowledge_base
```

### Embedding model not found

**Verify model:**
```bash
kubectl exec -n failure-monitoring deployment/ollama -- ollama list
```

**Re-pull model:**
```bash
kubectl exec -n failure-monitoring deployment/ollama -- ollama pull nomic-embed-text
```

### Document upload fails

**Check backend logs:**
```bash
kubectl logs -n failure-monitoring deployment/dashboard
```

**Common issues:**
- Qdrant not reachable (check QDRANT_URL env var)
- Ollama not reachable (check OLLAMA_URL env var)
- Collection not initialized (restart dashboard)

### Search returns no results

**Possible causes:**
1. No documents uploaded yet
2. Query too different from uploaded content
3. Collection was deleted/recreated

**Verify documents exist:**
```bash
# Check point count in collection
kubectl exec -n failure-monitoring deployment/qdrant -- \
  wget -qO- http://localhost:6333/collections/knowledge_base
```

## Privacy & Security

### 100% Local Processing

- All embeddings generated locally by Ollama
- All vector searches happen in local Qdrant instance
- No external API calls
- No data leaves the Kubernetes cluster

### Data Persistence

- Qdrant data persists across pod restarts (PersistentVolumeClaim)
- Documents remain until explicitly deleted
- To completely clear data:
  ```bash
  kubectl delete pvc qdrant-storage -n failure-monitoring
  kubectl delete pod -n failure-monitoring -l app=qdrant
  ```

## Future Enhancements

1. **Multiple Collections:** Separate collections for different knowledge domains
2. **Metadata Filtering:** Search by source, date, or custom tags
3. **Relevance Tuning:** Adjust similarity thresholds
4. **Hybrid Search:** Combine vector search with keyword matching
5. **Document Preprocessing:** Extract text from PDFs, DOCX, etc.
6. **Source Attribution:** Show which specific documents were used in responses
7. **Vector Cache:** Cache embeddings for frequently asked questions

## References

- **Qdrant Documentation:** https://qdrant.tech/documentation/
- **Ollama Embeddings API:** https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embeddings
- **nomic-embed-text model:** https://ollama.com/library/nomic-embed-text
- **RAG Concept:** https://docs.anthropic.com/claude/docs/retrieval-augmented-generation-rag
