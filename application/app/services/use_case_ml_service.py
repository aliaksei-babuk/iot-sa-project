"""Enhanced ML service for specific use cases."""
import numpy as np
import librosa
import soundfile as sf
import logging
import pickle
import os
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime
import joblib
from concurrent.futures import ThreadPoolExecutor
import asyncio

from app.config import settings, UseCaseType
from app.schemas.use_cases import (
    TrafficAnalysisRequest, TrafficAnalysisResult, TrafficEventType,
    SirenDetectionRequest, SirenDetectionResult, SirenType,
    NoiseMappingRequest, NoiseMappingResult, NoiseLevel,
    IndustrialMonitoringRequest, IndustrialMonitoringResult, IndustrialAnomalyType,
    WildlifeMonitoringRequest, WildlifeMonitoringResult, WildlifeSpecies,
    UnifiedAnalysisRequest, UnifiedAnalysisResult
)

logger = logging.getLogger(__name__)


class UseCaseMLService:
    """Enhanced ML service for specific use cases."""
    
    def __init__(self):
        self.models = {}
        self.feature_extractors = {}
        self._load_models()
        self.executor = ThreadPoolExecutor(max_workers=4)
    
    def _load_models(self):
        """Load ML models for all use cases."""
        try:
            # Create model storage directory
            os.makedirs(settings.model_storage_path, exist_ok=True)
            
            # Load models for each use case
            self._load_traffic_model()
            self._load_siren_model()
            self._load_noise_model()
            self._load_industrial_model()
            self._load_wildlife_model()
            
            logger.info("All use case models loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load use case models: {e}")
            # Fallback to mock models
            self._create_mock_models()
    
    def _load_traffic_model(self):
        """Load traffic monitoring model."""
        model_path = os.path.join(settings.model_storage_path, "traffic_classification.pkl")
        if os.path.exists(model_path):
            self.models[UseCaseType.TRAFFIC_MONITORING] = joblib.load(model_path)
        else:
            self.models[UseCaseType.TRAFFIC_MONITORING] = self._create_mock_traffic_model()
    
    def _load_siren_model(self):
        """Load siren detection model."""
        model_path = os.path.join(settings.model_storage_path, "siren_detection.pkl")
        if os.path.exists(model_path):
            self.models[UseCaseType.SIREN_DETECTION] = joblib.load(model_path)
        else:
            self.models[UseCaseType.SIREN_DETECTION] = self._create_mock_siren_model()
    
    def _load_noise_model(self):
        """Load noise mapping model."""
        model_path = os.path.join(settings.model_storage_path, "noise_classification.pkl")
        if os.path.exists(model_path):
            self.models[UseCaseType.NOISE_MAPPING] = joblib.load(model_path)
        else:
            self.models[UseCaseType.NOISE_MAPPING] = self._create_mock_noise_model()
    
    def _load_industrial_model(self):
        """Load industrial monitoring model."""
        model_path = os.path.join(settings.model_storage_path, "industrial_anomaly.pkl")
        if os.path.exists(model_path):
            self.models[UseCaseType.INDUSTRIAL_MONITORING] = joblib.load(model_path)
        else:
            self.models[UseCaseType.INDUSTRIAL_MONITORING] = self._create_mock_industrial_model()
    
    def _load_wildlife_model(self):
        """Load wildlife monitoring model."""
        model_path = os.path.join(settings.model_storage_path, "wildlife_classification.pkl")
        if os.path.exists(model_path):
            self.models[UseCaseType.WILDLIFE_MONITORING] = joblib.load(model_path)
        else:
            self.models[UseCaseType.WILDLIFE_MONITORING] = self._create_mock_wildlife_model()
    
    def _create_mock_models(self):
        """Create mock models for all use cases."""
        self.models[UseCaseType.TRAFFIC_MONITORING] = self._create_mock_traffic_model()
        self.models[UseCaseType.SIREN_DETECTION] = self._create_mock_siren_model()
        self.models[UseCaseType.NOISE_MAPPING] = self._create_mock_noise_model()
        self.models[UseCaseType.INDUSTRIAL_MONITORING] = self._create_mock_industrial_model()
        self.models[UseCaseType.WILDLIFE_MONITORING] = self._create_mock_wildlife_model()
    
    def _create_mock_traffic_model(self):
        """Create mock traffic classification model."""
        class MockTrafficModel:
            def predict_proba(self, X):
                n_samples = X.shape[0]
                proba = np.random.random((n_samples, 5))  # 5 traffic event types
                return proba / proba.sum(axis=1, keepdims=True)
            
            def predict(self, X):
                proba = self.predict_proba(X)
                return np.argmax(proba, axis=1)
        
        return MockTrafficModel()
    
    def _create_mock_siren_model(self):
        """Create mock siren detection model."""
        class MockSirenModel:
            def predict_proba(self, X):
                n_samples = X.shape[0]
                proba = np.random.random((n_samples, 6))  # 6 siren types
                return proba / proba.sum(axis=1, keepdims=True)
            
            def predict(self, X):
                proba = self.predict_proba(X)
                return np.argmax(proba, axis=1)
        
        return MockSirenModel()
    
    def _create_mock_noise_model(self):
        """Create mock noise classification model."""
        class MockNoiseModel:
            def predict_proba(self, X):
                n_samples = X.shape[0]
                proba = np.random.random((n_samples, 5))  # 5 noise levels
                return proba / proba.sum(axis=1, keepdims=True)
            
            def predict(self, X):
                proba = self.predict_proba(X)
                return np.argmax(proba, axis=1)
        
        return MockNoiseModel()
    
    def _create_mock_industrial_model(self):
        """Create mock industrial anomaly detection model."""
        class MockIndustrialModel:
            def predict_proba(self, X):
                n_samples = X.shape[0]
                proba = np.random.random((n_samples, 6))  # 6 anomaly types
                return proba / proba.sum(axis=1, keepdims=True)
            
            def predict(self, X):
                proba = self.predict_proba(X)
                return np.argmax(proba, axis=1)
        
        return MockIndustrialModel()
    
    def _create_mock_wildlife_model(self):
        """Create mock wildlife classification model."""
        class MockWildlifeModel:
            def predict_proba(self, X):
                n_samples = X.shape[0]
                proba = np.random.random((n_samples, 6))  # 6 species types
                return proba / proba.sum(axis=1, keepdims=True)
            
            def predict(self, X):
                proba = self.predict_proba(X)
                return np.argmax(proba, axis=1)
        
        return MockWildlifeModel()
    
    def extract_enhanced_features(self, audio_data: np.ndarray, sample_rate: int) -> np.ndarray:
        """Extract enhanced features for all use cases."""
        try:
            features = []
            
            # Basic spectral features
            mfccs = librosa.feature.mfcc(y=audio_data, sr=sample_rate, n_mfcc=settings.mfcc_features_count)
            features.extend(np.mean(mfccs, axis=1))
            features.extend(np.std(mfccs, axis=1))
            
            # Spectral features
            spectral_centroids = librosa.feature.spectral_centroid(y=audio_data, sr=sample_rate)[0]
            features.append(np.mean(spectral_centroids))
            features.append(np.std(spectral_centroids))
            
            # Zero crossing rate
            zcr = librosa.feature.zero_crossing_rate(audio_data)[0]
            features.append(np.mean(zcr))
            features.append(np.std(zcr))
            
            # Spectral rolloff
            rolloff = librosa.feature.spectral_rolloff(y=audio_data, sr=sample_rate)[0]
            features.append(np.mean(rolloff))
            features.append(np.std(rolloff))
            
            # Chroma features
            chroma = librosa.feature.chroma_stft(y=audio_data, sr=sample_rate)
            features.extend(np.mean(chroma, axis=1))
            
            # Mel spectrogram
            mel_spec = librosa.feature.melspectrogram(y=audio_data, sr=sample_rate, n_mels=settings.mel_spectrogram_bins)
            features.extend(np.mean(mel_spec, axis=1)[:20])  # First 20 mel features
            
            # Spectral contrast
            contrast = librosa.feature.spectral_contrast(y=audio_data, sr=sample_rate)
            features.extend(np.mean(contrast, axis=1))
            
            # Tonnetz features
            tonnetz = librosa.feature.tonnetz(y=audio_data, sr=sample_rate)
            features.extend(np.mean(tonnetz, axis=1))
            
            # Rhythm features
            tempo, beats = librosa.beat.beat_track(y=audio_data, sr=sample_rate)
            features.append(tempo)
            features.append(len(beats))
            
            # Energy features
            rms = librosa.feature.rms(y=audio_data)[0]
            features.append(np.mean(rms))
            features.append(np.std(rms))
            
            return np.array(features)
            
        except Exception as e:
            logger.error(f"Failed to extract enhanced features: {e}")
            return np.zeros(100)  # Default feature vector size
    
    async def analyze_traffic(self, request: TrafficAnalysisRequest) -> TrafficAnalysisResult:
        """Analyze traffic patterns from audio data."""
        try:
            start_time = datetime.now()
            
            # Load and preprocess audio
            audio_data, sample_rate = librosa.load(
                request.audio_data, 
                sr=settings.audio_sample_rate,
                duration=settings.audio_duration
            )
            
            # Extract features
            features = self.extract_enhanced_features(audio_data, sample_rate)
            features = features.reshape(1, -1)
            
            # Get model predictions
            model = self.models[UseCaseType.TRAFFIC_MONITORING]
            proba = model.predict_proba(features)[0]
            prediction = model.predict(features)[0]
            
            # Map prediction to event type
            event_types = list(TrafficEventType)
            event_type = event_types[prediction] if prediction < len(event_types) else TrafficEventType.NORMAL_FLOW
            confidence = float(proba[prediction])
            
            # Calculate additional metrics
            traffic_density = float(np.mean(proba[1:3]))  # Congestion and incident probabilities
            congestion_level = float(proba[1])  # Congestion probability
            honk_count = int(np.sum(audio_data > 0.1) * 0.01)  # Rough honk count estimate
            vehicle_count = int(traffic_density * 50)  # Estimate based on density
            
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return TrafficAnalysisResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                event_type=event_type,
                confidence_score=confidence,
                traffic_density=traffic_density,
                congestion_level=congestion_level,
                honk_count=honk_count,
                vehicle_count_estimate=vehicle_count,
                processing_time_ms=processing_time,
                features={
                    "mfcc_mean": features[0][:13].tolist(),
                    "spectral_centroid": float(features[0][26]),
                    "zcr": float(features[0][28]),
                    "tempo": float(features[0][-3]),
                    "energy": float(features[0][-1])
                }
            )
            
        except Exception as e:
            logger.error(f"Failed to analyze traffic: {e}")
            return TrafficAnalysisResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                event_type=TrafficEventType.NORMAL_FLOW,
                confidence_score=0.0,
                traffic_density=0.0,
                congestion_level=0.0,
                honk_count=0,
                vehicle_count_estimate=0,
                processing_time_ms=0.0,
                features={}
            )
    
    async def detect_siren(self, request: SirenDetectionRequest) -> SirenDetectionResult:
        """Detect emergency sirens in audio data."""
        try:
            start_time = datetime.now()
            
            # Load and preprocess audio
            audio_data, sample_rate = librosa.load(
                request.audio_data, 
                sr=settings.audio_sample_rate,
                duration=settings.audio_duration
            )
            
            # Extract features
            features = self.extract_enhanced_features(audio_data, sample_rate)
            features = features.reshape(1, -1)
            
            # Get model predictions
            model = self.models[UseCaseType.SIREN_DETECTION]
            proba = model.predict_proba(features)[0]
            prediction = model.predict(features)[0]
            
            # Map prediction to siren type
            siren_types = list(SirenType)
            siren_type = siren_types[prediction] if prediction < len(siren_types) else None
            confidence = float(proba[prediction])
            
            # Determine if siren is detected
            siren_detected = confidence > settings.siren_confidence_threshold
            
            # Estimate direction and distance (mock implementation)
            direction_estimate = np.random.uniform(0, 360) if siren_detected else None
            distance_estimate = np.random.uniform(50, 500) if siren_detected else None
            
            # Calculate emergency level
            emergency_level = 1
            if siren_detected:
                if confidence > 0.9:
                    emergency_level = 5
                elif confidence > 0.8:
                    emergency_level = 4
                elif confidence > 0.7:
                    emergency_level = 3
                else:
                    emergency_level = 2
            
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return SirenDetectionResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                siren_detected=siren_detected,
                siren_type=siren_type,
                confidence_score=confidence,
                direction_estimate=direction_estimate,
                distance_estimate=distance_estimate,
                emergency_level=emergency_level,
                processing_time_ms=processing_time,
                features={
                    "mfcc_mean": features[0][:13].tolist(),
                    "spectral_centroid": float(features[0][26]),
                    "zcr": float(features[0][28]),
                    "tempo": float(features[0][-3]),
                    "energy": float(features[0][-1])
                }
            )
            
        except Exception as e:
            logger.error(f"Failed to detect siren: {e}")
            return SirenDetectionResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                siren_detected=False,
                siren_type=None,
                confidence_score=0.0,
                direction_estimate=None,
                distance_estimate=None,
                emergency_level=1,
                processing_time_ms=0.0,
                features={}
            )
    
    async def analyze_noise_mapping(self, request: NoiseMappingRequest) -> NoiseMappingResult:
        """Analyze noise levels for urban mapping."""
        try:
            start_time = datetime.now()
            
            # Load and preprocess audio
            audio_data, sample_rate = librosa.load(
                request.audio_data, 
                sr=settings.audio_sample_rate,
                duration=request.measurement_duration_s
            )
            
            # Calculate sound pressure level (SPL)
            rms = np.sqrt(np.mean(audio_data**2))
            spl_db = 20 * np.log10(rms) if rms > 0 else 0
            
            # Calculate Leq (Equivalent Continuous Sound Level)
            leq_db = spl_db  # Simplified calculation
            
            # Calculate Lmax and Lmin
            lmax_db = 20 * np.log10(np.max(np.abs(audio_data))) if np.max(np.abs(audio_data)) > 0 else 0
            lmin_db = 20 * np.log10(np.min(np.abs(audio_data[audio_data > 0]))) if np.any(audio_data > 0) else 0
            
            # Determine noise level category
            if spl_db < 40:
                noise_level = NoiseLevel.QUIET
            elif spl_db < 60:
                noise_level = NoiseLevel.MODERATE
            elif spl_db < 80:
                noise_level = NoiseLevel.LOUD
            elif spl_db < 100:
                noise_level = NoiseLevel.VERY_LOUD
            else:
                noise_level = NoiseLevel.EXTREME
            
            # Frequency analysis
            freqs = np.fft.fftfreq(len(audio_data), 1/sample_rate)
            fft = np.fft.fft(audio_data)
            magnitude = np.abs(fft)
            
            # Calculate frequency bands
            low_freq = np.mean(magnitude[(freqs >= 20) & (freqs <= 250)])
            mid_freq = np.mean(magnitude[(freqs >= 250) & (freqs <= 2000)])
            high_freq = np.mean(magnitude[(freqs >= 2000) & (freqs <= 8000)])
            
            frequency_analysis = {
                "low_frequency": float(low_freq),
                "mid_frequency": float(mid_freq),
                "high_frequency": float(high_freq)
            }
            
            # Temporal pattern (simplified)
            temporal_pattern = [float(x) for x in audio_data[::len(audio_data)//10]]  # 10 samples
            
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return NoiseMappingResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                spl_db=spl_db,
                leq_db=leq_db,
                lmax_db=lmax_db,
                lmin_db=lmin_db,
                noise_level=noise_level,
                frequency_analysis=frequency_analysis,
                temporal_pattern=temporal_pattern,
                processing_time_ms=processing_time,
                features={
                    "rms": float(rms),
                    "spectral_centroid": float(np.mean(librosa.feature.spectral_centroid(y=audio_data, sr=sample_rate)[0])),
                    "zcr": float(np.mean(librosa.feature.zero_crossing_rate(audio_data)[0]))
                }
            )
            
        except Exception as e:
            logger.error(f"Failed to analyze noise mapping: {e}")
            return NoiseMappingResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                spl_db=0.0,
                leq_db=0.0,
                lmax_db=0.0,
                lmin_db=0.0,
                noise_level=NoiseLevel.QUIET,
                frequency_analysis={},
                temporal_pattern=[],
                processing_time_ms=0.0,
                features={}
            )
    
    async def analyze_industrial_monitoring(self, request: IndustrialMonitoringRequest) -> IndustrialMonitoringResult:
        """Analyze industrial machinery for anomalies."""
        try:
            start_time = datetime.now()
            
            # Load and preprocess audio
            audio_data, sample_rate = librosa.load(
                request.audio_data, 
                sr=settings.audio_sample_rate,
                duration=settings.audio_duration
            )
            
            # Extract features
            features = self.extract_enhanced_features(audio_data, sample_rate)
            features = features.reshape(1, -1)
            
            # Get model predictions
            model = self.models[UseCaseType.INDUSTRIAL_MONITORING]
            proba = model.predict_proba(features)[0]
            prediction = model.predict(features)[0]
            
            # Map prediction to anomaly type
            anomaly_types = list(IndustrialAnomalyType)
            anomaly_type = anomaly_types[prediction] if prediction < len(anomaly_types) else IndustrialAnomalyType.NORMAL_OPERATION
            confidence = float(proba[prediction])
            
            # Determine if anomaly is detected
            anomaly_detected = confidence > settings.anomaly_detection_threshold and anomaly_type != IndustrialAnomalyType.NORMAL_OPERATION
            
            # Calculate health score
            health_score = 1.0 - confidence if anomaly_detected else 1.0
            
            # Estimate vibration level
            vibration_level = float(np.std(audio_data))
            
            # Estimate temperature (mock implementation)
            temperature_estimate = 25.0 + (confidence * 20) if anomaly_detected else 25.0
            
            # Generate maintenance recommendation
            maintenance_recommendation = None
            if anomaly_detected:
                if anomaly_type == IndustrialAnomalyType.BEARING_FAILURE:
                    maintenance_recommendation = "Replace bearing assembly immediately"
                elif anomaly_type == IndustrialAnomalyType.BELT_MISALIGNMENT:
                    maintenance_recommendation = "Realign belt and check tension"
                elif anomaly_type == IndustrialAnomalyType.CAVITATION:
                    maintenance_recommendation = "Check pump operation and fluid levels"
                else:
                    maintenance_recommendation = "Schedule maintenance inspection"
            
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return IndustrialMonitoringResult(
                device_id=request.device_id,
                machinery_id=request.machinery_id,
                location=request.location,
                timestamp=request.timestamp,
                anomaly_detected=anomaly_detected,
                anomaly_type=anomaly_type if anomaly_detected else None,
                confidence_score=confidence,
                health_score=health_score,
                vibration_level=vibration_level,
                temperature_estimate=temperature_estimate,
                maintenance_recommendation=maintenance_recommendation,
                processing_time_ms=processing_time,
                features={
                    "mfcc_mean": features[0][:13].tolist(),
                    "spectral_centroid": float(features[0][26]),
                    "zcr": float(features[0][28]),
                    "tempo": float(features[0][-3]),
                    "energy": float(features[0][-1])
                }
            )
            
        except Exception as e:
            logger.error(f"Failed to analyze industrial monitoring: {e}")
            return IndustrialMonitoringResult(
                device_id=request.device_id,
                machinery_id=request.machinery_id,
                location=request.location,
                timestamp=request.timestamp,
                anomaly_detected=False,
                anomaly_type=None,
                confidence_score=0.0,
                health_score=1.0,
                vibration_level=0.0,
                temperature_estimate=25.0,
                maintenance_recommendation=None,
                processing_time_ms=0.0,
                features={}
            )
    
    async def analyze_wildlife_monitoring(self, request: WildlifeMonitoringRequest) -> WildlifeMonitoringResult:
        """Analyze wildlife sounds for species identification."""
        try:
            start_time = datetime.now()
            
            # Load and preprocess audio
            audio_data, sample_rate = librosa.load(
                request.audio_data, 
                sr=settings.audio_sample_rate,
                duration=settings.audio_duration
            )
            
            # Extract features
            features = self.extract_enhanced_features(audio_data, sample_rate)
            features = features.reshape(1, -1)
            
            # Get model predictions
            model = self.models[UseCaseType.WILDLIFE_MONITORING]
            proba = model.predict_proba(features)[0]
            prediction = model.predict(features)[0]
            
            # Map prediction to species
            species_types = list(WildlifeSpecies)
            species_detected = [species_types[prediction]] if prediction < len(species_types) else [WildlifeSpecies.UNKNOWN]
            species_confidence = {species_types[i]: float(proba[i]) for i in range(len(species_types))}
            
            # Calculate biodiversity index
            biodiversity_index = float(np.sum(proba > 0.1) / len(proba))
            
            # Calculate activity level
            activity_level = float(np.mean(np.abs(audio_data)))
            
            # Determine migration indicator (mock implementation)
            migration_indicator = biodiversity_index > 0.5 and activity_level > 0.1
            
            # Determine conservation status (mock implementation)
            conservation_status = "stable" if biodiversity_index > 0.3 else "threatened"
            
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return WildlifeMonitoringResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                species_detected=species_detected,
                species_confidence=species_confidence,
                biodiversity_index=biodiversity_index,
                activity_level=activity_level,
                migration_indicator=migration_indicator,
                conservation_status=conservation_status,
                processing_time_ms=processing_time,
                features={
                    "mfcc_mean": features[0][:13].tolist(),
                    "spectral_centroid": float(features[0][26]),
                    "zcr": float(features[0][28]),
                    "tempo": float(features[0][-3]),
                    "energy": float(features[0][-1])
                }
            )
            
        except Exception as e:
            logger.error(f"Failed to analyze wildlife monitoring: {e}")
            return WildlifeMonitoringResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                species_detected=[],
                species_confidence={},
                biodiversity_index=0.0,
                activity_level=0.0,
                migration_indicator=False,
                conservation_status="unknown",
                processing_time_ms=0.0,
                features={}
            )
    
    async def analyze_unified(self, request: UnifiedAnalysisRequest) -> UnifiedAnalysisResult:
        """Perform unified analysis across multiple use cases."""
        try:
            start_time = datetime.now()
            results = {}
            alerts_generated = []
            recommendations = []
            
            # Process each use case
            for use_case in request.use_cases:
                if use_case == UseCaseType.TRAFFIC_MONITORING:
                    traffic_request = TrafficAnalysisRequest(
                        device_id=request.device_id,
                        location=request.location,
                        audio_data=request.audio_data,
                        timestamp=request.timestamp,
                        metadata=request.metadata
                    )
                    result = await self.analyze_traffic(traffic_request)
                    results[use_case] = result.dict()
                    
                    if result.congestion_level > settings.congestion_threshold:
                        alerts_generated.append(f"Traffic congestion detected at {request.location}")
                        recommendations.append("Consider traffic rerouting")
                
                elif use_case == UseCaseType.SIREN_DETECTION:
                    siren_request = SirenDetectionRequest(
                        device_id=request.device_id,
                        location=request.location,
                        audio_data=request.audio_data,
                        timestamp=request.timestamp,
                        metadata=request.metadata
                    )
                    result = await self.detect_siren(siren_request)
                    results[use_case] = result.dict()
                    
                    if result.siren_detected:
                        alerts_generated.append(f"Emergency siren detected: {result.siren_type}")
                        recommendations.append("Alert emergency services")
                
                elif use_case == UseCaseType.NOISE_MAPPING:
                    noise_request = NoiseMappingRequest(
                        device_id=request.device_id,
                        location=request.location,
                        audio_data=request.audio_data,
                        timestamp=request.timestamp,
                        metadata=request.metadata
                    )
                    result = await self.analyze_noise_mapping(noise_request)
                    results[use_case] = result.dict()
                    
                    if result.noise_level in [NoiseLevel.VERY_LOUD, NoiseLevel.EXTREME]:
                        alerts_generated.append(f"Noise violation detected: {result.spl_db:.1f} dB")
                        recommendations.append("Investigate noise source")
                
                elif use_case == UseCaseType.INDUSTRIAL_MONITORING:
                    industrial_request = IndustrialMonitoringRequest(
                        device_id=request.device_id,
                        machinery_id=request.metadata.get("machinery_id", "unknown") if request.metadata else "unknown",
                        location=request.location,
                        audio_data=request.audio_data,
                        timestamp=request.timestamp,
                        metadata=request.metadata
                    )
                    result = await self.analyze_industrial_monitoring(industrial_request)
                    results[use_case] = result.dict()
                    
                    if result.anomaly_detected:
                        alerts_generated.append(f"Machinery anomaly detected: {result.anomaly_type}")
                        recommendations.append(result.maintenance_recommendation or "Schedule maintenance")
                
                elif use_case == UseCaseType.WILDLIFE_MONITORING:
                    wildlife_request = WildlifeMonitoringRequest(
                        device_id=request.device_id,
                        location=request.location,
                        audio_data=request.audio_data,
                        timestamp=request.timestamp,
                        metadata=request.metadata
                    )
                    result = await self.analyze_wildlife_monitoring(wildlife_request)
                    results[use_case] = result.dict()
                    
                    if result.migration_indicator:
                        alerts_generated.append("Wildlife migration pattern detected")
                        recommendations.append("Update conservation monitoring")
            
            # Calculate overall confidence
            confidences = [result.get("confidence_score", 0.0) for result in results.values()]
            overall_confidence = float(np.mean(confidences)) if confidences else 0.0
            
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return UnifiedAnalysisResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                use_cases=request.use_cases,
                results=results,
                overall_confidence=overall_confidence,
                processing_time_ms=processing_time,
                alerts_generated=alerts_generated,
                recommendations=recommendations
            )
            
        except Exception as e:
            logger.error(f"Failed to perform unified analysis: {e}")
            return UnifiedAnalysisResult(
                device_id=request.device_id,
                location=request.location,
                timestamp=request.timestamp,
                use_cases=request.use_cases,
                results={},
                overall_confidence=0.0,
                processing_time_ms=0.0,
                alerts_generated=[],
                recommendations=[]
            )


# Global use case ML service instance
use_case_ml_service = UseCaseMLService()
