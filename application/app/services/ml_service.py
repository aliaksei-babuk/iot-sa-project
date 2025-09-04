"""ML service for sound analytics and drone detection."""
import numpy as np
import librosa
import soundfile as sf
import logging
import pickle
import os
from typing import Optional, Dict, Any, Tuple
from datetime import datetime
import joblib

from app.config import settings
from app.schemas.telemetry import ProcessingResult

logger = logging.getLogger(__name__)


class MLService:
    """Machine Learning service for sound analytics."""
    
    def __init__(self):
        self.drone_detection_model = None
        self.sound_classifier = None
        self.feature_extractor = None
        self._load_models()
    
    def _load_models(self):
        """Load ML models."""
        try:
            # Create model storage directory
            os.makedirs(settings.model_storage_path, exist_ok=True)
            
            # Load drone detection model
            drone_model_path = os.path.join(settings.model_storage_path, "drone_detection_model.pkl")
            if os.path.exists(drone_model_path):
                self.drone_detection_model = joblib.load(drone_model_path)
                logger.info("Drone detection model loaded successfully")
            else:
                logger.warning("Drone detection model not found, using mock model")
                self.drone_detection_model = self._create_mock_model()
            
            # Load sound classifier
            classifier_path = os.path.join(settings.model_storage_path, "sound_classifier.pkl")
            if os.path.exists(classifier_path):
                self.sound_classifier = joblib.load(classifier_path)
                logger.info("Sound classifier loaded successfully")
            else:
                logger.warning("Sound classifier not found, using mock classifier")
                self.sound_classifier = self._create_mock_classifier()
            
        except Exception as e:
            logger.error(f"Failed to load ML models: {e}")
            # Fallback to mock models
            self.drone_detection_model = self._create_mock_model()
            self.sound_classifier = self._create_mock_classifier()
    
    def _create_mock_model(self):
        """Create a mock drone detection model for POC."""
        class MockDroneDetectionModel:
            def predict_proba(self, X):
                # Mock prediction - returns random probabilities
                n_samples = X.shape[0]
                proba = np.random.random((n_samples, 2))
                # Normalize to sum to 1
                proba = proba / proba.sum(axis=1, keepdims=True)
                return proba
            
            def predict(self, X):
                proba = self.predict_proba(X)
                return (proba[:, 1] > 0.5).astype(int)
        
        return MockDroneDetectionModel()
    
    def _create_mock_classifier(self):
        """Create a mock sound classifier for POC."""
        class MockSoundClassifier:
            def predict(self, X):
                # Mock classification - returns random classes
                n_samples = X.shape[0]
                classes = ['drone', 'aircraft', 'vehicle', 'ambient', 'unknown']
                return np.random.choice(classes, n_samples)
            
            def predict_proba(self, X):
                # Mock probabilities
                n_samples = X.shape[0]
                n_classes = 5
                proba = np.random.random((n_samples, n_classes))
                return proba / proba.sum(axis=1, keepdims=True)
        
        return MockSoundClassifier()
    
    def extract_audio_features(self, audio_data: np.ndarray, sample_rate: int) -> np.ndarray:
        """Extract features from audio data."""
        try:
            features = []
            
            # MFCC features
            mfccs = librosa.feature.mfcc(y=audio_data, sr=sample_rate, n_mfcc=13)
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
            
            # Mel-frequency cepstral coefficients
            mel_spec = librosa.feature.melspectrogram(y=audio_data, sr=sample_rate)
            features.extend(np.mean(mel_spec, axis=1)[:10])  # First 10 mel features
            
            return np.array(features)
            
        except Exception as e:
            logger.error(f"Failed to extract audio features: {e}")
            # Return zero features as fallback
            return np.zeros(50)  # Default feature vector size
    
    def process_audio_file(self, file_path: str) -> ProcessingResult:
        """Process audio file for drone detection."""
        try:
            start_time = datetime.now()
            
            # Load audio file
            audio_data, sample_rate = librosa.load(file_path, sr=settings.audio_sample_rate)
            
            # Extract features
            features = self.extract_audio_features(audio_data, sample_rate)
            features = features.reshape(1, -1)  # Reshape for model input
            
            # Drone detection
            drone_prob = self.drone_detection_model.predict_proba(features)[0]
            is_drone_detected = drone_prob[1] > 0.5
            confidence_score = float(drone_prob[1])
            
            # Sound classification
            classification = self.sound_classifier.predict(features)[0]
            classification_proba = self.sound_classifier.predict_proba(features)[0]
            
            # Calculate processing time
            processing_time = (datetime.now() - start_time).total_seconds()
            
            # Create result
            result = ProcessingResult(
                is_drone_detected=is_drone_detected,
                confidence_score=confidence_score,
                classification=classification,
                features={
                    "mfcc_mean": features[0][:13].tolist(),
                    "mfcc_std": features[0][13:26].tolist(),
                    "spectral_centroid_mean": float(features[0][26]),
                    "spectral_centroid_std": float(features[0][27]),
                    "zcr_mean": float(features[0][28]),
                    "zcr_std": float(features[0][29]),
                    "spectral_rolloff_mean": float(features[0][30]),
                    "spectral_rolloff_std": float(features[0][31]),
                    "chroma_features": features[0][32:44].tolist(),
                    "mel_features": features[0][44:54].tolist()
                },
                processing_time=processing_time
            )
            
            logger.info(f"Audio processing completed: drone_detected={is_drone_detected}, "
                       f"confidence={confidence_score:.3f}, classification={classification}")
            
            return result
            
        except Exception as e:
            logger.error(f"Failed to process audio file {file_path}: {e}")
            # Return error result
            return ProcessingResult(
                is_drone_detected=False,
                confidence_score=0.0,
                classification="error",
                features={},
                processing_time=0.0
            )
    
    def process_audio_data(self, audio_data: bytes, sample_rate: int) -> ProcessingResult:
        """Process raw audio data for drone detection."""
        try:
            # Convert bytes to numpy array
            audio_array = np.frombuffer(audio_data, dtype=np.float32)
            
            # Resample if necessary
            if sample_rate != settings.audio_sample_rate:
                audio_array = librosa.resample(
                    audio_array, 
                    orig_sr=sample_rate, 
                    target_sr=settings.audio_sample_rate
                )
            
            # Extract features
            features = self.extract_audio_features(audio_array, settings.audio_sample_rate)
            features = features.reshape(1, -1)
            
            # Drone detection
            drone_prob = self.drone_detection_model.predict_proba(features)[0]
            is_drone_detected = drone_prob[1] > 0.5
            confidence_score = float(drone_prob[1])
            
            # Sound classification
            classification = self.sound_classifier.predict(features)[0]
            
            # Calculate processing time
            processing_time = 0.1  # Mock processing time
            
            return ProcessingResult(
                is_drone_detected=is_drone_detected,
                confidence_score=confidence_score,
                classification=classification,
                features={},
                processing_time=processing_time
            )
            
        except Exception as e:
            logger.error(f"Failed to process audio data: {e}")
            return ProcessingResult(
                is_drone_detected=False,
                confidence_score=0.0,
                classification="error",
                features={},
                processing_time=0.0
            )
    
    def train_drone_detection_model(self, training_data: list) -> bool:
        """Train drone detection model with provided data."""
        try:
            # This is a placeholder for actual model training
            # In a real implementation, you would:
            # 1. Load training data
            # 2. Extract features
            # 3. Train the model
            # 4. Save the model
            
            logger.info("Drone detection model training completed (mock)")
            return True
            
        except Exception as e:
            logger.error(f"Failed to train drone detection model: {e}")
            return False
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get information about loaded models."""
        return {
            "drone_detection_model": {
                "loaded": self.drone_detection_model is not None,
                "type": type(self.drone_detection_model).__name__
            },
            "sound_classifier": {
                "loaded": self.sound_classifier is not None,
                "type": type(self.sound_classifier).__name__
            },
            "feature_extractor": {
                "loaded": True,
                "type": "librosa_based"
            }
        }


# Global ML service instance
ml_service = MLService()
