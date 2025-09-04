"""Database service for managing connections and sessions."""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool
from app.config import settings
import logging

logger = logging.getLogger(__name__)


class DatabaseService:
    """Database service for managing connections."""
    
    def __init__(self):
        self.engine = None
        self.SessionLocal = None
        self._setup_database()
    
    def _setup_database(self):
        """Setup database engine and session factory."""
        try:
            # Create engine with connection pooling
            self.engine = create_engine(
                settings.database_url,
                poolclass=StaticPool,
                pool_pre_ping=True,
                echo=settings.debug
            )
            
            # Create session factory
            self.SessionLocal = sessionmaker(
                autocommit=False,
                autoflush=False,
                bind=self.engine
            )
            
            logger.info("Database connection established successfully")
            
        except Exception as e:
            logger.error(f"Failed to setup database: {e}")
            raise
    
    def get_session(self) -> Session:
        """Get database session."""
        return self.SessionLocal()
    
    def close_session(self, session: Session):
        """Close database session."""
        session.close()
    
    def create_tables(self):
        """Create all database tables."""
        from app.models.database import Base
        try:
            Base.metadata.create_all(bind=self.engine)
            logger.info("Database tables created successfully")
        except Exception as e:
            logger.error(f"Failed to create tables: {e}")
            raise


# Global database service instance
db_service = DatabaseService()
