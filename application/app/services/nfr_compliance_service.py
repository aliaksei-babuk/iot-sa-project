"""NFR compliance monitoring and validation service."""
import time
import logging
import asyncio
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import statistics

from app.config import settings
from app.services.metrics_service import metrics_service

logger = logging.getLogger(__name__)


class NFRStatus(str, Enum):
    """NFR compliance status."""
    COMPLIANT = "compliant"
    WARNING = "warning"
    VIOLATION = "violation"
    CRITICAL = "critical"


@dataclass
class NFRMetric:
    """NFR metric data structure."""
    nfr_id: str
    metric_name: str
    current_value: float
    target_value: float
    unit: str
    status: NFRStatus
    timestamp: datetime
    trend: str  # "improving", "stable", "degrading"


class NFRComplianceService:
    """Service for monitoring and validating NFR compliance."""
    
    def __init__(self):
        self.metrics_history = {}
        self.alerts = []
        self.compliance_status = {}
        self._initialize_nfr_targets()
    
    def _initialize_nfr_targets(self):
        """Initialize NFR targets and thresholds."""
        self.nfr_targets = {
            "NFR-01": {  # Performance
                "metrics": {
                    "p95_latency_ms": {"target": 100, "warning": 80, "critical": 120},
                    "throughput_rps": {"target": 100, "warning": 80, "critical": 50},
                    "cold_start_ms": {"target": 200, "warning": 150, "critical": 300}
                }
            },
            "NFR-02": {  # Scalability
                "metrics": {
                    "concurrent_devices": {"target": 10000, "warning": 8000, "critical": 5000},
                    "throughput_degradation": {"target": 0.01, "warning": 0.05, "critical": 0.1},
                    "scaling_response_s": {"target": 30, "warning": 45, "critical": 60}
                }
            },
            "NFR-03": {  # Availability
                "metrics": {
                    "uptime_percent": {"target": 99.9, "warning": 99.5, "critical": 99.0},
                    "failover_time_s": {"target": 60, "warning": 90, "critical": 120},
                    "health_check_s": {"target": 5, "warning": 8, "critical": 15}
                }
            },
            "NFR-04": {  # Reliability
                "metrics": {
                    "data_loss_rate": {"target": 0.001, "warning": 0.005, "critical": 0.01},
                    "message_delivery_rate": {"target": 0.99, "warning": 0.95, "critical": 0.90},
                    "retry_success_rate": {"target": 0.99, "warning": 0.95, "critical": 0.90}
                }
            },
            "NFR-05": {  # Security
                "metrics": {
                    "mTLS_enforcement": {"target": 1.0, "warning": 0.95, "critical": 0.90},
                    "vulnerability_count": {"target": 0, "warning": 1, "critical": 5},
                    "auth_failure_rate": {"target": 0.01, "warning": 0.05, "critical": 0.10}
                }
            },
            "NFR-06": {  # Privacy/Compliance
                "metrics": {
                    "gdpr_compliance": {"target": 1.0, "warning": 0.95, "critical": 0.90},
                    "pii_anonymization": {"target": 1.0, "warning": 0.95, "critical": 0.90},
                    "data_retention_compliance": {"target": 1.0, "warning": 0.95, "critical": 0.90}
                }
            },
            "NFR-07": {  # Interoperability
                "metrics": {
                    "protocol_support": {"target": 3, "warning": 2, "critical": 1},
                    "cross_cloud_compatibility": {"target": 1.0, "warning": 0.95, "critical": 0.90},
                    "api_consistency": {"target": 1.0, "warning": 0.95, "critical": 0.90}
                }
            },
            "NFR-08": {  # Observability
                "metrics": {
                    "metrics_coverage": {"target": 1.0, "warning": 0.95, "critical": 0.90},
                    "query_response_s": {"target": 5, "warning": 8, "critical": 15},
                    "log_completeness": {"target": 1.0, "warning": 0.95, "critical": 0.90}
                }
            },
            "NFR-09": {  # Cost
                "metrics": {
                    "cost_per_event": {"target": 0.01, "warning": 0.015, "critical": 0.02},
                    "cost_variance_percent": {"target": 0.05, "warning": 0.10, "critical": 0.20},
                    "resource_utilization": {"target": 0.80, "warning": 0.90, "critical": 0.95}
                }
            },
            "NFR-10": {  # Maintainability
                "metrics": {
                    "code_coverage": {"target": 0.90, "warning": 0.80, "critical": 0.70},
                    "deployment_time_min": {"target": 5, "warning": 10, "critical": 15},
                    "cyclomatic_complexity": {"target": 10, "warning": 15, "critical": 20}
                }
            }
        }
    
    def record_metric(self, nfr_id: str, metric_name: str, value: float, unit: str = ""):
        """Record a metric value for NFR compliance monitoring."""
        try:
            timestamp = datetime.utcnow()
            
            # Store metric in history
            if nfr_id not in self.metrics_history:
                self.metrics_history[nfr_id] = {}
            if metric_name not in self.metrics_history[nfr_id]:
                self.metrics_history[nfr_id][metric_name] = []
            
            self.metrics_history[nfr_id][metric_name].append({
                "value": value,
                "timestamp": timestamp,
                "unit": unit
            })
            
            # Keep only last 1000 records per metric
            if len(self.metrics_history[nfr_id][metric_name]) > 1000:
                self.metrics_history[nfr_id][metric_name] = self.metrics_history[nfr_id][metric_name][-1000:]
            
            # Evaluate compliance
            self._evaluate_compliance(nfr_id, metric_name, value, timestamp)
            
            logger.debug(f"Recorded metric {metric_name} for {nfr_id}: {value} {unit}")
            
        except Exception as e:
            logger.error(f"Failed to record metric {metric_name} for {nfr_id}: {e}")
    
    def _evaluate_compliance(self, nfr_id: str, metric_name: str, value: float, timestamp: datetime):
        """Evaluate compliance for a specific metric."""
        try:
            if nfr_id not in self.nfr_targets:
                return
            
            if metric_name not in self.nfr_targets[nfr_id]["metrics"]:
                return
            
            targets = self.nfr_targets[nfr_id]["metrics"][metric_name]
            target_value = targets["target"]
            warning_threshold = targets["warning"]
            critical_threshold = targets["critical"]
            
            # Determine status based on thresholds
            if value <= critical_threshold:
                status = NFRStatus.CRITICAL
            elif value <= warning_threshold:
                status = NFRStatus.WARNING
            elif value <= target_value:
                status = NFRStatus.COMPLIANT
            else:
                status = NFRStatus.VIOLATION
            
            # Calculate trend
            trend = self._calculate_trend(nfr_id, metric_name)
            
            # Create metric object
            metric = NFRMetric(
                nfr_id=nfr_id,
                metric_name=metric_name,
                current_value=value,
                target_value=target_value,
                unit=targets.get("unit", ""),
                status=status,
                timestamp=timestamp,
                trend=trend
            )
            
            # Update compliance status
            if nfr_id not in self.compliance_status:
                self.compliance_status[nfr_id] = {}
            self.compliance_status[nfr_id][metric_name] = metric
            
            # Generate alert if needed
            if status in [NFRStatus.WARNING, NFRStatus.VIOLATION, NFRStatus.CRITICAL]:
                self._generate_alert(metric)
            
        except Exception as e:
            logger.error(f"Failed to evaluate compliance for {nfr_id}.{metric_name}: {e}")
    
    def _calculate_trend(self, nfr_id: str, metric_name: str) -> str:
        """Calculate trend for a metric."""
        try:
            if nfr_id not in self.metrics_history or metric_name not in self.metrics_history[nfr_id]:
                return "stable"
            
            history = self.metrics_history[nfr_id][metric_name]
            if len(history) < 2:
                return "stable"
            
            # Get last 10 values
            recent_values = [h["value"] for h in history[-10:]]
            
            if len(recent_values) < 2:
                return "stable"
            
            # Calculate simple trend
            first_half = recent_values[:len(recent_values)//2]
            second_half = recent_values[len(recent_values)//2:]
            
            first_avg = statistics.mean(first_half)
            second_avg = statistics.mean(second_half)
            
            change_percent = (second_avg - first_avg) / first_avg if first_avg != 0 else 0
            
            if change_percent > 0.05:
                return "degrading"
            elif change_percent < -0.05:
                return "improving"
            else:
                return "stable"
                
        except Exception as e:
            logger.error(f"Failed to calculate trend for {nfr_id}.{metric_name}: {e}")
            return "stable"
    
    def _generate_alert(self, metric: NFRMetric):
        """Generate alert for NFR violation."""
        try:
            alert = {
                "id": f"nfr_{metric.nfr_id}_{metric.metric_name}_{int(time.time())}",
                "nfr_id": metric.nfr_id,
                "metric_name": metric.metric_name,
                "status": metric.status.value,
                "current_value": metric.current_value,
                "target_value": metric.target_value,
                "unit": metric.unit,
                "timestamp": metric.timestamp,
                "trend": metric.trend,
                "message": f"NFR {metric.nfr_id} violation: {metric.metric_name} = {metric.current_value} {metric.unit} (target: {metric.target_value} {metric.unit})"
            }
            
            self.alerts.append(alert)
            
            # Keep only last 1000 alerts
            if len(self.alerts) > 1000:
                self.alerts = self.alerts[-1000:]
            
            logger.warning(f"NFR Alert: {alert['message']}")
            
        except Exception as e:
            logger.error(f"Failed to generate alert for {metric.nfr_id}.{metric.metric_name}: {e}")
    
    def get_compliance_status(self, nfr_id: Optional[str] = None) -> Dict[str, Any]:
        """Get compliance status for NFRs."""
        try:
            if nfr_id:
                if nfr_id in self.compliance_status:
                    return {
                        nfr_id: {
                            metric_name: {
                                "current_value": metric.current_value,
                                "target_value": metric.target_value,
                                "unit": metric.unit,
                                "status": metric.status.value,
                                "trend": metric.trend,
                                "timestamp": metric.timestamp.isoformat()
                            }
                            for metric_name, metric in self.compliance_status[nfr_id].items()
                        }
                    }
                else:
                    return {}
            else:
                return {
                    nfr_id: {
                        metric_name: {
                            "current_value": metric.current_value,
                            "target_value": metric.target_value,
                            "unit": metric.unit,
                            "status": metric.status.value,
                            "trend": metric.trend,
                            "timestamp": metric.timestamp.isoformat()
                        }
                        for metric_name, metric in metrics.items()
                    }
                    for nfr_id, metrics in self.compliance_status.items()
                }
                
        except Exception as e:
            logger.error(f"Failed to get compliance status: {e}")
            return {}
    
    def get_alerts(self, limit: int = 100, status: Optional[NFRStatus] = None) -> List[Dict[str, Any]]:
        """Get NFR alerts."""
        try:
            alerts = self.alerts[-limit:] if limit else self.alerts
            
            if status:
                alerts = [alert for alert in alerts if alert["status"] == status.value]
            
            return sorted(alerts, key=lambda x: x["timestamp"], reverse=True)
            
        except Exception as e:
            logger.error(f"Failed to get alerts: {e}")
            return []
    
    def get_nfr_summary(self) -> Dict[str, Any]:
        """Get NFR compliance summary."""
        try:
            summary = {
                "total_nfrs": len(self.nfr_targets),
                "compliant_nfrs": 0,
                "warning_nfrs": 0,
                "violation_nfrs": 0,
                "critical_nfrs": 0,
                "overall_status": "compliant",
                "last_updated": datetime.utcnow().isoformat()
            }
            
            for nfr_id, metrics in self.compliance_status.items():
                nfr_status = "compliant"
                for metric_name, metric in metrics.items():
                    if metric.status == NFRStatus.CRITICAL:
                        nfr_status = "critical"
                        summary["critical_nfrs"] += 1
                        break
                    elif metric.status == NFRStatus.VIOLATION:
                        nfr_status = "violation"
                        summary["violation_nfrs"] += 1
                    elif metric.status == NFRStatus.WARNING:
                        nfr_status = "warning"
                        summary["warning_nfrs"] += 1
                    elif metric.status == NFRStatus.COMPLIANT:
                        summary["compliant_nfrs"] += 1
                
                if nfr_status == "critical":
                    summary["overall_status"] = "critical"
                elif nfr_status == "violation" and summary["overall_status"] != "critical":
                    summary["overall_status"] = "violation"
                elif nfr_status == "warning" and summary["overall_status"] not in ["critical", "violation"]:
                    summary["overall_status"] = "warning"
            
            return summary
            
        except Exception as e:
            logger.error(f"Failed to get NFR summary: {e}")
            return {}
    
    def get_metric_history(self, nfr_id: str, metric_name: str, hours: int = 24) -> List[Dict[str, Any]]:
        """Get metric history for a specific NFR metric."""
        try:
            if nfr_id not in self.metrics_history or metric_name not in self.metrics_history[nfr_id]:
                return []
            
            cutoff_time = datetime.utcnow() - timedelta(hours=hours)
            history = self.metrics_history[nfr_id][metric_name]
            
            filtered_history = [
                {
                    "value": h["value"],
                    "timestamp": h["timestamp"].isoformat(),
                    "unit": h["unit"]
                }
                for h in history
                if h["timestamp"] >= cutoff_time
            ]
            
            return sorted(filtered_history, key=lambda x: x["timestamp"])
            
        except Exception as e:
            logger.error(f"Failed to get metric history for {nfr_id}.{metric_name}: {e}")
            return []
    
    def validate_nfr_compliance(self) -> Dict[str, Any]:
        """Validate overall NFR compliance."""
        try:
            validation_result = {
                "timestamp": datetime.utcnow().isoformat(),
                "overall_compliance": True,
                "nfrs_validated": 0,
                "nfrs_passing": 0,
                "nfrs_failing": 0,
                "details": {}
            }
            
            for nfr_id in self.nfr_targets:
                nfr_compliance = True
                nfr_details = {}
                
                if nfr_id in self.compliance_status:
                    for metric_name, metric in self.compliance_status[nfr_id].items():
                        is_compliant = metric.status == NFRStatus.COMPLIANT
                        nfr_compliance = nfr_compliance and is_compliant
                        
                        nfr_details[metric_name] = {
                            "compliant": is_compliant,
                            "current_value": metric.current_value,
                            "target_value": metric.target_value,
                            "status": metric.status.value
                        }
                
                validation_result["nfrs_validated"] += 1
                if nfr_compliance:
                    validation_result["nfrs_passing"] += 1
                else:
                    validation_result["nfrs_failing"] += 1
                    validation_result["overall_compliance"] = False
                
                validation_result["details"][nfr_id] = {
                    "compliant": nfr_compliance,
                    "metrics": nfr_details
                }
            
            return validation_result
            
        except Exception as e:
            logger.error(f"Failed to validate NFR compliance: {e}")
            return {
                "timestamp": datetime.utcnow().isoformat(),
                "overall_compliance": False,
                "error": str(e)
            }


# Global NFR compliance service instance
nfr_compliance_service = NFRComplianceService()
