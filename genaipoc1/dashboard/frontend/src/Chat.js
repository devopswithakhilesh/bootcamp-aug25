import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import './Chat.css';

const API_URL = process.env.REACT_APP_API_URL || '';

function Chat() {
  const [messages, setMessages] = useState([
    {
      role: 'assistant',
      content: 'Hello! I\'m your local AI assistant (Gemma 2B). I\'m running entirely on your computer - no data leaves your machine. Ask me anything about the failure monitoring system, errors, or general questions!',
      timestamp: new Date()
    }
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim() || loading) return;

    const userMessage = {
      role: 'user',
      content: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setLoading(true);

    try {
      // Prepare conversation history (last 10 messages)
      const history = messages.slice(-10).map(msg => ({
        role: msg.role,
        content: msg.content
      }));

      const response = await axios.post(`${API_URL}/api/chat`, {
        message: input,
        history: history
      });

      const aiMessage = {
        role: 'assistant',
        content: response.data.response,
        model: response.data.model,
        ragEnabled: response.data.rag_enabled,
        sourcesUsed: response.data.sources_used,
        timestamp: new Date()
      };

      setMessages(prev => [...prev, aiMessage]);
    } catch (error) {
      const errorMessage = {
        role: 'assistant',
        content: `Sorry, I encountered an error: ${error.response?.data?.error || error.message}. Make sure Ollama is running with the gemma:2b model.`,
        error: true,
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setLoading(false);
    }
  };

  const clearChat = () => {
    setMessages([
      {
        role: 'assistant',
        content: 'Chat cleared. How can I help you?',
        timestamp: new Date()
      }
    ]);
  };

  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleTimeString();
  };

  return (
    <div className="chat-container">
      <div className="chat-header">
        <div>
          <h2>AI Chat Assistant</h2>
          <p className="chat-subtitle">Powered by Ollama Gemma 2B (100% Local)</p>
        </div>
        <button onClick={clearChat} className="btn-clear-chat">Clear Chat</button>
      </div>

      <div className="chat-messages">
        {messages.map((msg, index) => (
          <div key={index} className={`message ${msg.role} ${msg.error ? 'error' : ''}`}>
            <div className="message-header">
              <span className="message-role">
                {msg.role === 'user' ? 'You' : 'AI Assistant'}
              </span>
              <span className="message-time">{formatTimestamp(msg.timestamp)}</span>
            </div>
            <div className="message-content">
              {msg.content}
            </div>
            {msg.model && (
              <div className="message-model">Model: {msg.model}</div>
            )}
            {msg.ragEnabled && msg.sourcesUsed > 0 && (
              <div className="message-rag">
                📚 Used {msg.sourcesUsed} document{msg.sourcesUsed > 1 ? 's' : ''} from knowledge base
              </div>
            )}
          </div>
        ))}
        {loading && (
          <div className="message assistant loading">
            <div className="message-header">
              <span className="message-role">AI Assistant</span>
            </div>
            <div className="message-content">
              <div className="typing-indicator">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={sendMessage} className="chat-input-form">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask me anything..."
          className="chat-input"
          disabled={loading}
        />
        <button type="submit" disabled={!input.trim() || loading} className="btn-send">
          {loading ? 'Thinking...' : 'Send'}
        </button>
      </form>

      <div className="chat-footer">
        <p>🔒 100% Private - All AI processing happens locally on your machine</p>
      </div>
    </div>
  );
}

export default Chat;
