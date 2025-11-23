"""
Healthcare Workflow Library MCP Server

Provides agent-accessible tools for deploying and managing standardized
clinical pathways, FHIR integrations, and healthcare workflows.
"""

import asyncio
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from mcp import Server, Tool
from mcp.server.streamable import streamable_http
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor

from .services.n8n_service import N8NService
from .services.erpnext_service import ERPNextService
from .services.fhir_service import FHIRService
from .tools.workflow_deployment import (
    deploy_clinical_pathway,
    list_available_pathways,
    get_pathway_status,
)
from .tools.fhir_mapping import (
    sync_fhir_resources,
    validate_fhir_mapping,
    configure_fhir_sync,
)
from .tools.bpmn_import import (
    import_bpmn_pathway,
    convert_bpmn_to_n8n,
)
from .tools.standards_query import (
    query_standards,
    get_standard_details,
)


# Initialize OpenTelemetry tracing
def init_tracing():
    """Initialize OpenTelemetry tracing for observability"""
    trace.set_tracer_provider(TracerProvider())
    otlp_exporter = OTLPSpanExporter(
        endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector:4317"),
        insecure=True,
    )
    trace.get_tracer_provider().add_span_processor(
        BatchSpanProcessor(otlp_exporter)
    )


# Initialize tracer
tracer = trace.get_tracer(__name__)


# Create MCP server instance
mcp_server = Server(
    name="healthcare-workflow-library",
    version="1.0.0",
    description="Healthcare Workflow Library - Standardized clinical pathways and FHIR integration"
)


# Initialize services
n8n_service = N8NService(
    base_url=os.getenv("N8N_URL", "http://n8n:5678"),
    api_key=os.getenv("N8N_API_KEY")
)

erpnext_service = ERPNextService(
    base_url=os.getenv("ERPNEXT_URL", "https://erpnext.example.com"),
    api_key=os.getenv("ERPNEXT_API_KEY"),
    api_secret=os.getenv("ERPNEXT_API_SECRET")
)

fhir_service = FHIRService(
    base_url=os.getenv("FHIR_SERVER_URL", "https://fhir.example.com"),
    auth_token=os.getenv("FHIR_SERVER_AUTH")
)


# Tool: Deploy Clinical Pathway
@mcp_server.tool()
@tracer.start_as_current_span("deploy_clinical_pathway")
async def deploy_pathway(
    pathway_name: str,
    target_environment: str = "production",
    enable_fhir_sync: bool = True
) -> Dict[str, Any]:
    """
    Deploy a standard clinical pathway to n8n.

    Args:
        pathway_name: Name of the pathway (e.g., 'patient-admission', 'medication-ordering')
        target_environment: Target environment (production, staging, development)
        enable_fhir_sync: Whether to enable FHIR synchronization

    Returns:
        Deployment status including workflow ID and verification results
    """
    span = trace.get_current_span()
    span.set_attribute("pathway.name", pathway_name)
    span.set_attribute("environment", target_environment)

    try:
        result = await deploy_clinical_pathway(
            pathway_name=pathway_name,
            target_environment=target_environment,
            enable_fhir_sync=enable_fhir_sync,
            n8n_service=n8n_service
        )
        span.set_attribute("deployment.status", "success")
        return result
    except Exception as e:
        span.set_attribute("deployment.status", "failed")
        span.record_exception(e)
        raise


@mcp_server.tool()
@tracer.start_as_current_span("list_available_pathways")
async def list_pathways(
    domain: Optional[str] = None,
    standard: Optional[str] = None
) -> List[Dict[str, Any]]:
    """
    List available clinical pathways.

    Args:
        domain: Filter by domain (clinical, operational, reporting)
        standard: Filter by standard (bpmn, cmmn, dmn)

    Returns:
        List of available pathways with metadata
    """
    span = trace.get_current_span()
    if domain:
        span.set_attribute("filter.domain", domain)
    if standard:
        span.set_attribute("filter.standard", standard)

    return await list_available_pathways(domain=domain, standard=standard)


@mcp_server.tool()
@tracer.start_as_current_span("sync_fhir_resources")
async def sync_fhir(
    resource_type: str,
    direction: str = "bidirectional",
    patient_filter: Optional[str] = None
) -> Dict[str, Any]:
    """
    Trigger FHIR resource synchronization.

    Args:
        resource_type: FHIR resource type (Patient, Encounter, Observation, etc.)
        direction: Sync direction (to_fhir, to_erpnext, bidirectional)
        patient_filter: Optional filter for patients (e.g., 'active=true')

    Returns:
        Sync status including records synced and any errors
    """
    span = trace.get_current_span()
    span.set_attribute("fhir.resource_type", resource_type)
    span.set_attribute("fhir.direction", direction)

    try:
        result = await sync_fhir_resources(
            resource_type=resource_type,
            direction=direction,
            patient_filter=patient_filter,
            n8n_service=n8n_service,
            fhir_service=fhir_service,
            erpnext_service=erpnext_service
        )
        span.set_attribute("sync.records_processed", result.get("records_synced", 0))
        return result
    except Exception as e:
        span.record_exception(e)
        raise


@mcp_server.tool()
@tracer.start_as_current_span("import_bpmn_pathway")
async def import_pathway(
    bpmn_file_path: str,
    pathway_name: str,
    description: Optional[str] = None,
    auto_deploy: bool = False
) -> Dict[str, Any]:
    """
    Import a new BPMN clinical pathway into the library.

    Args:
        bpmn_file_path: Path to BPMN XML file
        pathway_name: Name for the pathway
        description: Optional description
        auto_deploy: Whether to automatically deploy to n8n after import

    Returns:
        Import status and pathway details
    """
    span = trace.get_current_span()
    span.set_attribute("pathway.name", pathway_name)
    span.set_attribute("auto_deploy", auto_deploy)

    try:
        result = await import_bpmn_pathway(
            bpmn_file_path=bpmn_file_path,
            pathway_name=pathway_name,
            description=description,
            auto_deploy=auto_deploy,
            n8n_service=n8n_service
        )
        return result
    except Exception as e:
        span.record_exception(e)
        raise


@mcp_server.tool()
@tracer.start_as_current_span("configure_uds_reporting")
async def configure_uds(
    health_center_id: str,
    enable_table_6a: bool = True,
    enable_table_6b: bool = True,
    submission_schedule: str = "monthly"
) -> Dict[str, Any]:
    """
    Configure UDS+ reporting workflows for a health center.

    Args:
        health_center_id: HRSA health center ID
        enable_table_6a: Enable Table 6A (diagnoses and services)
        enable_table_6b: Enable Table 6B (quality measures)
        submission_schedule: Submission schedule (monthly, quarterly, annual)

    Returns:
        Configuration status and workflow IDs
    """
    span = trace.get_current_span()
    span.set_attribute("health_center.id", health_center_id)

    # TODO: Implement UDS+ configuration logic
    return {
        "status": "configured",
        "health_center_id": health_center_id,
        "workflows": {
            "table_6a_collection": "workflow-id-6a" if enable_table_6a else None,
            "table_6b_calculation": "workflow-id-6b" if enable_table_6b else None
        },
        "schedule": submission_schedule
    }


@mcp_server.tool()
@tracer.start_as_current_span("validate_fhir_mapping")
async def validate_mapping(
    erpnext_doctype: str,
    fhir_resource: str,
    test_record_id: Optional[str] = None
) -> Dict[str, Any]:
    """
    Validate FHIR mapping for an ERPNext DocType.

    Args:
        erpnext_doctype: ERPNext DocType name (e.g., 'Patient')
        fhir_resource: FHIR resource type (e.g., 'Patient')
        test_record_id: Optional test record ID for validation

    Returns:
        Validation report with mapping coverage and errors
    """
    span = trace.get_current_span()
    span.set_attribute("doctype", erpnext_doctype)
    span.set_attribute("fhir_resource", fhir_resource)

    try:
        result = await validate_fhir_mapping(
            erpnext_doctype=erpnext_doctype,
            fhir_resource=fhir_resource,
            test_record_id=test_record_id,
            erpnext_service=erpnext_service,
            fhir_service=fhir_service
        )
        return result
    except Exception as e:
        span.record_exception(e)
        raise


@mcp_server.tool()
@tracer.start_as_current_span("query_standards")
async def query_standards_tool(
    query: str,
    standard_type: Optional[str] = None
) -> List[Dict[str, Any]]:
    """
    Query available healthcare standards and pathways.

    Args:
        query: Search query
        standard_type: Filter by standard type (fhir, bpmn, dmn, gs1)

    Returns:
        List of matching standards with details
    """
    return await query_standards(query=query, standard_type=standard_type)


@mcp_server.tool()
@tracer.start_as_current_span("get_pathway_status")
async def get_status(pathway_name: str) -> Dict[str, Any]:
    """
    Get deployment status of a clinical pathway.

    Args:
        pathway_name: Name of the pathway

    Returns:
        Status information including deployment, execution statistics, and health
    """
    span = trace.get_current_span()
    span.set_attribute("pathway.name", pathway_name)

    try:
        result = await get_pathway_status(
            pathway_name=pathway_name,
            n8n_service=n8n_service
        )
        return result
    except Exception as e:
        span.record_exception(e)
        raise


@mcp_server.tool()
@tracer.start_as_current_span("convert_bpmn_to_n8n")
async def convert_bpmn(
    bpmn_file_path: str,
    output_path: Optional[str] = None
) -> Dict[str, Any]:
    """
    Convert BPMN XML to n8n workflow JSON.

    Args:
        bpmn_file_path: Path to BPMN XML file
        output_path: Optional output path for n8n JSON

    Returns:
        Conversion status and n8n workflow definition
    """
    span = trace.get_current_span()

    try:
        result = await convert_bpmn_to_n8n(
            bpmn_file_path=bpmn_file_path,
            output_path=output_path
        )
        return result
    except Exception as e:
        span.record_exception(e)
        raise


async def main():
    """Main entry point for MCP server"""
    # Initialize tracing
    init_tracing()

    # Get configuration
    host = os.getenv("MCP_HOST", "0.0.0.0")
    port = int(os.getenv("MCP_PORT", "8080"))

    print(f"Starting Healthcare Workflow Library MCP Server on {host}:{port}")
    print(f"n8n URL: {n8n_service.base_url}")
    print(f"ERPNext URL: {erpnext_service.base_url}")
    print(f"FHIR Server URL: {fhir_service.base_url}")

    # Start server with HTTP/SSE transport
    await streamable_http(
        server=mcp_server,
        host=host,
        port=port
    )


if __name__ == "__main__":
    asyncio.run(main())
