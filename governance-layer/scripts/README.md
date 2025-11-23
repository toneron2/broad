# Scripts

Development, build, and deployment automation scripts.

## Planned Scripts

### Development
- `setup-dev-env.sh` - Install dependencies for local development
- `run-local-edge.sh` - Start edge emulator/simulator
- `run-local-cloud.sh` - Start local cloud services (n8n, Firestore emulator)
- `sync-devices.sh` - Push code to test devices

### Build
- `build-aosp.sh` - Compile custom AOSP image
- `build-edge-apk.sh` - Build Android app (ESN agents)
- `build-cloud-images.sh` - Build Docker images for cloud services
- `build-all.sh` - Full system build

### Testing
- `run-unit-tests.sh` - Execute unit test suite
- `run-integration-tests.sh` - Execute integration tests
- `run-performance-tests.sh` - Run benchmarks
- `run-security-audit.sh` - Security scans and compliance checks

### Deployment
- `deploy-cloud-dev.sh` - Deploy to GCP development environment
- `deploy-cloud-staging.sh` - Deploy to staging
- `deploy-cloud-prod.sh` - Production deployment (Phase 2+)
- `flash-device.sh` - Flash custom AOSP to Pixel device

### Utilities
- `generate-certs.sh` - Generate TLS certificates for QUIC
- `setup-gcp-project.sh` - Initialize GCP resources
- `backup-data.sh` - Backup device registry and workflows
- `monitor-system.sh` - Real-time system monitoring

---

**Status**: Specification phase - no scripts yet
