# Configuration

Environment-specific configuration files.

## Structure

```
config/
├── development/    # Local development settings
├── staging/        # Staging environment
├── production/     # Production settings (Phase 2+)
└── examples/       # Example configurations
```

## Configuration Files

### Edge Device Config
- `edge-config.yaml` - Agent settings, reasoning parameters
- `bio-auth-config.yaml` - Biometric thresholds and policies
- `mcp-tools.yaml` - Tool definitions and permissions
- `privacy-rules.yaml` - Local privacy enforcement rules

### Cloud Config
- `cloud-config.yaml` - Service endpoints and resources
- `gcp-project.yaml` - GCP project settings
- `n8n-workflows.json` - Workflow definitions (Phase 0)
- `firestore-rules.yaml` - Database security rules

### Protocol Config
- `quic-config.yaml` - WebTransport/QUIC parameters
- `heartbeat-config.yaml` - Heartbeat frequency and payload
- `a2a-protocol.yaml` - Agent-to-agent comm settings

### Logic Engine Config (Phase 1)
- `logic-paradigms.yaml` - Enabled logic types and weights
- `unicode-dictionary.yaml` - Semantic mapping definitions
- `synthesis-rules.yaml` - Paradigm combination policies

## Environment Variables

Key environment variables for deployment:

```bash
# GCP
GOOGLE_CLOUD_PROJECT=esn-dev-001
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json

# Edge
ESN_DEVICE_ID=pixel10-001
ESN_CLOUD_ENDPOINT=wss://cloud.esn.example.com
ESN_LOCAL_MODEL_PATH=/data/local/llm/model.gguf

# Security
ESN_BIO_AUTH_ENABLED=true
ESN_TRIPLE_LOCK_MODE=strict
ESN_PRIVACY_LEVEL=high
```

---

**Status**: Specification phase - no configs yet
