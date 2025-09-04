"""Metrics collection middleware."""
import time
import logging
from fastapi import Request, Response
from typing import Callable

from app.services.metrics_service import metrics_service

logger = logging.getLogger(__name__)


class MetricsMiddleware:
    """Middleware for collecting HTTP request metrics."""
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        request = Request(scope, receive)
        start_time = time.time()
        
        # Process request
        response_sent = False
        
        async def send_wrapper(message):
            nonlocal response_sent
            if message["type"] == "http.response.start" and not response_sent:
                response_sent = True
                
                # Calculate duration
                duration = time.time() - start_time
                
                # Extract metrics
                method = request.method
                path = request.url.path
                status_code = message.get("status", 500)
                
                # Record metrics
                try:
                    metrics_service.record_request(method, path, status_code, duration)
                except Exception as e:
                    logger.error(f"Failed to record request metrics: {e}")
            
            await send(message)
        
        await self.app(scope, receive, send_wrapper)
