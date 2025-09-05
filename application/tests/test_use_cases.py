"""Use case specific testing framework."""
import pytest
import asyncio
import numpy as np
from datetime import datetime
from unittest.mock import Mock, patch

from app.services.use_case_ml_service import use_case_ml_service
from app.schemas.use_cases import (
    TrafficAnalysisRequest, SirenDetectionRequest, NoiseMappingRequest,
    IndustrialMonitoringRequest, WildlifeMonitoringRequest, UnifiedAnalysisRequest
)
from app.config import UseCaseType


class TestTrafficMonitoring:
    """Test traffic monitoring use case."""
    
    @pytest.mark.asyncio
    async def test_traffic_analysis(self):
        """Test traffic analysis functionality."""
        # Create mock audio data
        audio_data = np.random.random(44100).astype(np.float32).tobytes()
        
        # Create request
        request = TrafficAnalysisRequest(
            device_id="test-device-001",
            location="Test Intersection",
            audio_data=audio_data,
            metadata={"test": True}
        )
        
        # Perform analysis
        result = await use_case_ml_service.analyze_traffic(request)
        
        # Verify result structure
        assert result.device_id == "test-device-001"
        assert result.location == "Test Intersection"
        assert result.confidence_score >= 0.0
        assert result.confidence_score <= 1.0
        assert result.traffic_density >= 0.0
        assert result.traffic_density <= 1.0
        assert result.congestion_level >= 0.0
        assert result.congestion_level <= 1.0
        assert result.honk_count >= 0
        assert result.vehicle_count_estimate >= 0
        assert result.processing_time_ms >= 0.0
    
    def test_traffic_model_loading(self):
        """Test traffic model loading."""
        assert UseCaseType.TRAFFIC_MONITORING in use_case_ml_service.models
        model = use_case_ml_service.models[UseCaseType.TRAFFIC_MONITORING]
        assert model is not None
    
    def test_traffic_feature_extraction(self):
        """Test traffic feature extraction."""
        # Create mock audio data
        audio_data = np.random.random(22050).astype(np.float32)
        
        # Extract features
        features = use_case_ml_service.extract_enhanced_features(audio_data, 22050)
        
        # Verify features
        assert isinstance(features, np.ndarray)
        assert len(features) > 0
        assert not np.isnan(features).any()


class TestSirenDetection:
    """Test siren detection use case."""
    
    @pytest.mark.asyncio
    async def test_siren_detection(self):
        """Test siren detection functionality."""
        # Create mock audio data
        audio_data = np.random.random(44100).astype(np.float32).tobytes()
        
        # Create request
        request = SirenDetectionRequest(
            device_id="test-device-002",
            location="Emergency Zone",
            audio_data=audio_data,
            emergency_priority=True,
            metadata={"test": True}
        )
        
        # Perform detection
        result = await use_case_ml_service.detect_siren(request)
        
        # Verify result structure
        assert result.device_id == "test-device-002"
        assert result.location == "Emergency Zone"
        assert isinstance(result.siren_detected, bool)
        assert result.confidence_score >= 0.0
        assert result.confidence_score <= 1.0
        assert result.emergency_level >= 1
        assert result.emergency_level <= 5
        assert result.processing_time_ms >= 0.0
    
    def test_siren_model_loading(self):
        """Test siren model loading."""
        assert UseCaseType.SIREN_DETECTION in use_case_ml_service.models
        model = use_case_ml_service.models[UseCaseType.SIREN_DETECTION]
        assert model is not None


class TestNoiseMapping:
    """Test noise mapping use case."""
    
    @pytest.mark.asyncio
    async def test_noise_mapping_analysis(self):
        """Test noise mapping analysis functionality."""
        # Create mock audio data
        audio_data = np.random.random(44100).astype(np.float32).tobytes()
        
        # Create request
        request = NoiseMappingRequest(
            device_id="test-device-003",
            location="Urban Zone",
            audio_data=audio_data,
            measurement_duration_s=300,
            metadata={"test": True}
        )
        
        # Perform analysis
        result = await use_case_ml_service.analyze_noise_mapping(request)
        
        # Verify result structure
        assert result.device_id == "test-device-003"
        assert result.location == "Urban Zone"
        assert result.spl_db >= 0.0
        assert result.leq_db >= 0.0
        assert result.lmax_db >= 0.0
        assert result.lmin_db >= 0.0
        assert result.processing_time_ms >= 0.0
        assert isinstance(result.frequency_analysis, dict)
        assert isinstance(result.temporal_pattern, list)
    
    def test_noise_model_loading(self):
        """Test noise model loading."""
        assert UseCaseType.NOISE_MAPPING in use_case_ml_service.models
        model = use_case_ml_service.models[UseCaseType.NOISE_MAPPING]
        assert model is not None


class TestIndustrialMonitoring:
    """Test industrial monitoring use case."""
    
    @pytest.mark.asyncio
    async def test_industrial_monitoring_analysis(self):
        """Test industrial monitoring analysis functionality."""
        # Create mock audio data
        audio_data = np.random.random(44100).astype(np.float32).tobytes()
        
        # Create request
        request = IndustrialMonitoringRequest(
            device_id="test-device-004",
            machinery_id="machine-001",
            location="Factory Floor",
            audio_data=audio_data,
            machinery_type="pump",
            operating_conditions={"pressure": 100, "temperature": 25},
            metadata={"test": True}
        )
        
        # Perform analysis
        result = await use_case_ml_service.analyze_industrial_monitoring(request)
        
        # Verify result structure
        assert result.device_id == "test-device-004"
        assert result.machinery_id == "machine-001"
        assert result.location == "Factory Floor"
        assert isinstance(result.anomaly_detected, bool)
        assert result.confidence_score >= 0.0
        assert result.confidence_score <= 1.0
        assert result.health_score >= 0.0
        assert result.health_score <= 1.0
        assert result.vibration_level >= 0.0
        assert result.vibration_level <= 1.0
        assert result.processing_time_ms >= 0.0
    
    def test_industrial_model_loading(self):
        """Test industrial model loading."""
        assert UseCaseType.INDUSTRIAL_MONITORING in use_case_ml_service.models
        model = use_case_ml_service.models[UseCaseType.INDUSTRIAL_MONITORING]
        assert model is not None


class TestWildlifeMonitoring:
    """Test wildlife monitoring use case."""
    
    @pytest.mark.asyncio
    async def test_wildlife_monitoring_analysis(self):
        """Test wildlife monitoring analysis functionality."""
        # Create mock audio data
        audio_data = np.random.random(44100).astype(np.float32).tobytes()
        
        # Create request
        request = WildlifeMonitoringRequest(
            device_id="test-device-005",
            location="Forest Reserve",
            audio_data=audio_data,
            habitat_type="temperate_forest",
            season="spring",
            time_of_day="dawn",
            metadata={"test": True}
        )
        
        # Perform analysis
        result = await use_case_ml_service.analyze_wildlife_monitoring(request)
        
        # Verify result structure
        assert result.device_id == "test-device-005"
        assert result.location == "Forest Reserve"
        assert isinstance(result.species_detected, list)
        assert isinstance(result.species_confidence, dict)
        assert result.biodiversity_index >= 0.0
        assert result.biodiversity_index <= 1.0
        assert result.activity_level >= 0.0
        assert result.activity_level <= 1.0
        assert isinstance(result.migration_indicator, bool)
        assert result.processing_time_ms >= 0.0
    
    def test_wildlife_model_loading(self):
        """Test wildlife model loading."""
        assert UseCaseType.WILDLIFE_MONITORING in use_case_ml_service.models
        model = use_case_ml_service.models[UseCaseType.WILDLIFE_MONITORING]
        assert model is not None


class TestUnifiedAnalysis:
    """Test unified analysis functionality."""
    
    @pytest.mark.asyncio
    async def test_unified_analysis(self):
        """Test unified analysis across multiple use cases."""
        # Create mock audio data
        audio_data = np.random.random(44100).astype(np.float32).tobytes()
        
        # Create request
        request = UnifiedAnalysisRequest(
            device_id="test-device-006",
            location="Mixed Zone",
            audio_data=audio_data,
            use_cases=[UseCaseType.TRAFFIC_MONITORING, UseCaseType.SIREN_DETECTION],
            priority=3,
            metadata={"test": True}
        )
        
        # Perform analysis
        result = await use_case_ml_service.analyze_unified(request)
        
        # Verify result structure
        assert result.device_id == "test-device-006"
        assert result.location == "Mixed Zone"
        assert len(result.use_cases) == 2
        assert len(result.results) == 2
        assert result.overall_confidence >= 0.0
        assert result.overall_confidence <= 1.0
        assert result.processing_time_ms >= 0.0
        assert isinstance(result.alerts_generated, list)
        assert isinstance(result.recommendations, list)
    
    def test_all_use_cases_enabled(self):
        """Test that all use cases are enabled."""
        enabled_use_cases = [
            UseCaseType.TRAFFIC_MONITORING,
            UseCaseType.SIREN_DETECTION,
            UseCaseType.NOISE_MAPPING,
            UseCaseType.INDUSTRIAL_MONITORING,
            UseCaseType.WILDLIFE_MONITORING
        ]
        
        for use_case in enabled_use_cases:
            assert use_case in use_case_ml_service.models
            assert use_case_ml_service.models[use_case] is not None


class TestMLServiceIntegration:
    """Test ML service integration."""
    
    def test_feature_extraction_consistency(self):
        """Test that feature extraction is consistent."""
        # Create mock audio data
        audio_data = np.random.random(22050).astype(np.float32)
        
        # Extract features multiple times
        features1 = use_case_ml_service.extract_enhanced_features(audio_data, 22050)
        features2 = use_case_ml_service.extract_enhanced_features(audio_data, 22050)
        
        # Should be identical for same input
        assert np.array_equal(features1, features2)
    
    def test_model_prediction_consistency(self):
        """Test that model predictions are consistent."""
        # Create mock features
        features = np.random.random((1, 100))
        
        # Test traffic model
        traffic_model = use_case_ml_service.models[UseCaseType.TRAFFIC_MONITORING]
        pred1 = traffic_model.predict(features)
        pred2 = traffic_model.predict(features)
        
        # Should be identical for same input
        assert np.array_equal(pred1, pred2)
    
    def test_processing_time_reasonable(self):
        """Test that processing times are reasonable."""
        # Create mock audio data
        audio_data = np.random.random(22050).astype(np.float32)
        
        # Extract features and measure time
        import time
        start_time = time.time()
        features = use_case_ml_service.extract_enhanced_features(audio_data, 22050)
        processing_time = time.time() - start_time
        
        # Should complete within reasonable time (1 second)
        assert processing_time < 1.0


class TestErrorHandling:
    """Test error handling in use cases."""
    
    @pytest.mark.asyncio
    async def test_invalid_audio_data(self):
        """Test handling of invalid audio data."""
        # Create invalid audio data
        invalid_audio_data = b"invalid audio data"
        
        # Create request
        request = TrafficAnalysisRequest(
            device_id="test-device-007",
            location="Test Location",
            audio_data=invalid_audio_data,
            metadata={"test": True}
        )
        
        # Should handle gracefully
        result = await use_case_ml_service.analyze_traffic(request)
        
        # Should return result with default values
        assert result.device_id == "test-device-007"
        assert result.confidence_score == 0.0
    
    @pytest.mark.asyncio
    async def test_empty_audio_data(self):
        """Test handling of empty audio data."""
        # Create empty audio data
        empty_audio_data = b""
        
        # Create request
        request = SirenDetectionRequest(
            device_id="test-device-008",
            location="Test Location",
            audio_data=empty_audio_data,
            metadata={"test": True}
        )
        
        # Should handle gracefully
        result = await use_case_ml_service.detect_siren(request)
        
        # Should return result with default values
        assert result.device_id == "test-device-008"
        assert result.siren_detected == False


if __name__ == "__main__":
    pytest.main([__file__])
