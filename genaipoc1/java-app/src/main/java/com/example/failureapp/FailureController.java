package com.example.failureapp;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api")
public class FailureController {

    private static final Logger logger = LoggerFactory.getLogger(FailureController.class);
    private static final Map<String, Boolean> failureStates = new ConcurrentHashMap<>();
    private static List<byte[]> memoryLeak = new ArrayList<>();

    static {
        failureStates.put("http_500", false);
        failureStates.put("http_503", false);
        failureStates.put("timeout", false);
        failureStates.put("exception", false);
        failureStates.put("memory_leak", false);
        failureStates.put("cpu_spike", false);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();

        if (failureStates.get("http_500")) {
            simulateInternalServerError();
            response.put("status", "error");
            response.put("message", "Internal server error occurred");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }

        if (failureStates.get("http_503")) {
            simulateServiceUnavailable();
            response.put("status", "error");
            response.put("message", "Service temporarily unavailable");
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(response);
        }

        if (failureStates.get("timeout")) {
            simulateDatabaseTimeout();
            try {
                Thread.sleep(60000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        if (failureStates.get("exception")) {
            simulateNullPointerException();
        }

        response.put("status", "healthy");
        response.put("message", "Application is running normally");
        response.put("timestamp", new Date());
        logger.info("Health check: OK");
        return ResponseEntity.ok(response);
    }

    private void simulateInternalServerError() {
        logger.error("=== CRITICAL ERROR DETECTED ===");
        logger.error("Failed to process user request in PaymentService");
        logger.error("Request ID: {}, Session: {}, User: {}",
            UUID.randomUUID(), "session-abc-123", "user@example.com");

        try {
            processPayment(null);
        } catch (Exception e) {
            logger.error("Exception in payment processing chain", e);
            logger.error("Database connection pool exhausted: activeConnections=50, maxConnections=50");
            logger.error("Thread pool status: active=200, queued=500, rejected=25");
            logger.error("Memory usage: heap=1.8GB/2GB, non-heap=256MB/512MB");
        }
    }

    private void processPayment(String paymentId) throws Exception {
        logger.debug("Entering processPayment with paymentId: {}", paymentId);
        try {
            validatePaymentRequest(paymentId);
        } catch (Exception e) {
            throw new RuntimeException("Payment validation failed in transaction processor", e);
        }
    }

    private void validatePaymentRequest(String paymentId) throws Exception {
        logger.debug("Validating payment request");
        if (paymentId == null) {
            throw new IllegalArgumentException("PaymentId cannot be null - received from upstream service");
        }
    }

    private void simulateServiceUnavailable() {
        logger.error("=== SERVICE DEGRADATION ALERT ===");
        logger.error("External API integration failure detected");
        logger.error("Service: payment-gateway-api, Endpoint: https://api.payment-provider.com/v2/process");
        logger.error("Error: Connection refused - Unable to reach payment provider");
        logger.error("Retry attempts: 3/3 failed");
        logger.error("Circuit breaker status: OPEN");
        logger.error("Fallback mechanism: UNAVAILABLE");
        logger.error("Impact: All payment transactions are failing");
        logger.error("Upstream error: java.net.ConnectException: Connection timed out (Connection timed out)");
        logger.error("\tat java.base/java.net.PlainSocketImpl.socketConnect(Native Method)");
        logger.error("\tat java.base/java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:412)");
        logger.error("\tat com.example.failureapp.PaymentGatewayClient.connect(PaymentGatewayClient.java:156)");
    }

    private void simulateDatabaseTimeout() {
        logger.error("=== DATABASE PERFORMANCE ISSUE ===");
        logger.error("Query execution timeout detected");
        logger.error("Query: SELECT u.*, o.*, p.* FROM users u JOIN orders o ON u.id = o.user_id JOIN payments p ON o.id = p.order_id WHERE u.created_at > ? AND o.status = 'PENDING'");
        logger.error("Execution time: 30.5 seconds (timeout threshold: 30s)");
        logger.error("Database: postgres-prod-replica-2, Host: db.internal.company.com:5432");
        logger.error("Connection pool stats: waiting=45, active=50, idle=0, total=50");
        logger.error("Table locks: users(READ), orders(WRITE PENDING), payments(READ)");
        logger.error("Slow query log entry created: query_id=8675309");
        logger.warn("Possible cause: Missing index on orders.user_id or high table scan");
        logger.warn("Recommendation: Add composite index on (user_id, status, created_at)");
    }

    private void simulateNullPointerException() {
        logger.error("=== UNEXPECTED NULL REFERENCE ===");
        logger.error("NullPointerException in user session processing");
        logger.error("Request path: /api/user/profile/update, Method: POST");
        logger.error("User session data missing from cache");
        logger.error("Session ID: null (expected: valid session token)");
        logger.error("Cache status: Redis connection pool exhausted");

        try {
            getUserProfile(null);
        } catch (NullPointerException e) {
            logger.error("Failed to retrieve user profile", e);
            logger.error("Root cause: Session cache returned null for active user");
            logger.error("Stack trace analysis:");
            logger.error("\tat com.example.failureapp.UserService.getUserProfile(UserService.java:245)");
            logger.error("\tat com.example.failureapp.ProfileController.updateProfile(ProfileController.java:128)");
            logger.error("\tat com.example.failureapp.SecurityFilter.validateSession(SecurityFilter.java:89)");
            logger.error("Session cache miss rate: 35% (threshold: 10%)");
            logger.error("Redis latency: 250ms (threshold: 50ms)");
            throw e;
        }
    }

    private void getUserProfile(String sessionId) {
        logger.debug("Fetching user profile for session: {}", sessionId);
        String userId = sessionId.substring(0, 10); // This will throw NPE if sessionId is null
        logger.debug("Extracted userId: {}", userId);
    }

    @PostMapping("/failure/trigger/{type}")
    public ResponseEntity<Map<String, String>> triggerFailure(@PathVariable String type) {
        Map<String, String> response = new HashMap<>();

        logger.info("==========================================");
        logger.info("FAILURE INJECTION REQUEST RECEIVED");
        logger.info("Type: {}, Timestamp: {}", type, new Date());
        logger.info("==========================================");

        switch (type.toLowerCase()) {
            case "http_500":
                failureStates.put("http_500", true);
                logger.warn("ACTIVATED: Internal Server Error mode");
                logger.warn("Simulating: Payment processing failure with database exhaustion");
                response.put("message", "HTTP 500 failure mode activated");
                break;

            case "http_503":
                failureStates.put("http_503", true);
                logger.warn("ACTIVATED: Service Unavailable mode");
                logger.warn("Simulating: External payment gateway API failure");
                response.put("message", "HTTP 503 failure mode activated");
                break;

            case "timeout":
                failureStates.put("timeout", true);
                logger.warn("ACTIVATED: Database timeout mode");
                logger.warn("Simulating: Slow query with connection pool exhaustion");
                response.put("message", "Timeout failure mode activated");
                break;

            case "exception":
                failureStates.put("exception", true);
                logger.warn("ACTIVATED: NullPointerException mode");
                logger.warn("Simulating: Session cache failure with null reference");
                response.put("message", "Exception failure mode activated");
                break;

            case "memory_leak":
                failureStates.put("memory_leak", true);
                startMemoryLeak();
                logger.warn("ACTIVATED: Memory leak mode");
                logger.warn("Simulating: Unbounded cache growth / memory leak");
                response.put("message", "Memory leak failure mode activated");
                break;

            case "cpu_spike":
                failureStates.put("cpu_spike", true);
                startCpuSpike();
                logger.warn("ACTIVATED: CPU spike mode");
                logger.warn("Simulating: Inefficient algorithm / infinite loop");
                response.put("message", "CPU spike failure mode activated");
                break;

            default:
                logger.error("Unknown failure type requested: {}", type);
                response.put("error", "Unknown failure type: " + type);
                return ResponseEntity.badRequest().body(response);
        }

        response.put("type", type);
        response.put("status", "triggered");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/failure/clear/{type}")
    public ResponseEntity<Map<String, String>> clearFailure(@PathVariable String type) {
        Map<String, String> response = new HashMap<>();

        if (failureStates.containsKey(type.toLowerCase())) {
            failureStates.put(type.toLowerCase(), false);
            logger.info("CLEARED: {} failure mode", type);
            response.put("message", type + " failure mode cleared");
            response.put("type", type);
            response.put("status", "cleared");

            if ("memory_leak".equals(type.toLowerCase())) {
                memoryLeak.clear();
                System.gc();
                logger.info("Memory cleaned up, GC triggered");
            }

            return ResponseEntity.ok(response);
        } else {
            logger.error("Unknown failure type to clear: {}", type);
            response.put("error", "Unknown failure type: " + type);
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/failure/clear-all")
    public ResponseEntity<Map<String, String>> clearAllFailures() {
        failureStates.replaceAll((k, v) -> false);
        memoryLeak.clear();
        System.gc();
        logger.info("==========================================");
        logger.info("ALL FAILURE MODES CLEARED");
        logger.info("Application restored to normal operation");
        logger.info("==========================================");

        Map<String, String> response = new HashMap<>();
        response.put("message", "All failure modes cleared");
        response.put("status", "cleared");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/failure/status")
    public ResponseEntity<Map<String, Object>> getFailureStatus() {
        Map<String, Object> response = new HashMap<>();
        response.put("failures", failureStates);
        response.put("timestamp", new Date());
        return ResponseEntity.ok(response);
    }

    private void startMemoryLeak() {
        new Thread(() -> {
            logger.warn("Memory leak thread started - allocating 10MB/second");
            int iteration = 0;
            while (failureStates.get("memory_leak")) {
                try {
                    memoryLeak.add(new byte[10 * 1024 * 1024]);
                    iteration++;
                    if (iteration % 5 == 0) {
                        Runtime runtime = Runtime.getRuntime();
                        long usedMemory = (runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024;
                        long maxMemory = runtime.maxMemory() / 1024 / 1024;
                        logger.error("MEMORY LEAK ALERT: Iteration {}, Used: {}MB, Max: {}MB, Objects: {}",
                            iteration, usedMemory, maxMemory, memoryLeak.size());
                    }
                    Thread.sleep(1000);
                } catch (InterruptedException | OutOfMemoryError e) {
                    logger.error("Memory leak thread error: {}", e.getMessage());
                    logger.error("FATAL: Out of memory condition detected!");
                    logger.error("Heap dump would be written here in production");
                    break;
                }
            }
            logger.warn("Memory leak thread stopped");
        }).start();
    }

    private void startCpuSpike() {
        logger.warn("Starting CPU spike - creating 4 busy threads");
        for (int i = 0; i < 4; i++) {
            final int threadNum = i;
            new Thread(() -> {
                logger.debug("CPU spike thread {} started", threadNum);
                while (failureStates.get("cpu_spike")) {
                    Math.pow(Math.random(), Math.random());
                }
                logger.debug("CPU spike thread {} stopped", threadNum);
            }).start();
        }
    }

    @GetMapping("/test")
    public ResponseEntity<Map<String, String>> test() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Application is responding");
        response.put("timestamp", new Date().toString());
        logger.info("Test endpoint called - application healthy");
        return ResponseEntity.ok(response);
    }
}
