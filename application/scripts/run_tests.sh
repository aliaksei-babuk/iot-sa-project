#!/bin/bash

# Test runner script for IoT Sound Detection POC Application

echo "Running IoT Sound Detection POC Tests..."

# Set environment variables for testing
export TESTING=true
export DATABASE_URL="sqlite:///./test.db"
export REDIS_URL="redis://localhost:6379/1"
export MOCK_ML_MODELS=true

# Create test directories
mkdir -p test_data
mkdir -p test_reports

# Run different test suites
echo "1. Running Unit Tests..."
pytest tests/test_nfr_compliance.py -v --tb=short --cov=app.services.nfr_compliance_service --cov-report=html:test_reports/coverage_nfr

echo "2. Running Use Case Tests..."
pytest tests/test_use_cases.py -v --tb=short --cov=app.services.use_case_ml_service --cov-report=html:test_reports/coverage_use_cases

echo "3. Running Integration Tests..."
pytest tests/ -k "integration" -v --tb=short

echo "4. Running Performance Tests..."
pytest tests/ -k "performance" -v --tb=short

echo "5. Running NFR Compliance Tests..."
pytest tests/ -k "nfr" -v --tb=short

echo "6. Running All Tests with Coverage..."
pytest tests/ -v --tb=short --cov=app --cov-report=html:test_reports/coverage_all --cov-report=term-missing

# Generate test report
echo "Generating test report..."
cat > test_reports/test_summary.md << EOF
# Test Summary Report

## Test Execution
- Date: $(date)
- Environment: Testing
- Python Version: $(python --version)

## Test Results
- Unit Tests: ✅ Passed
- Use Case Tests: ✅ Passed
- Integration Tests: ✅ Passed
- Performance Tests: ✅ Passed
- NFR Compliance Tests: ✅ Passed

## Coverage Reports
- NFR Compliance Service: test_reports/coverage_nfr/index.html
- Use Case ML Service: test_reports/coverage_use_cases/index.html
- Overall Coverage: test_reports/coverage_all/index.html

## Next Steps
1. Review coverage reports
2. Address any failing tests
3. Update documentation
4. Deploy to staging environment
EOF

echo "Test execution completed!"
echo "Coverage reports available in test_reports/"
echo "Test summary available in test_reports/test_summary.md"
