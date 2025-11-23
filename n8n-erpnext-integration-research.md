# n8n-ERPNext Integration Research

## Executive Summary

n8n has native, built-in support for ERPNext with a dedicated ERPNext node. The integration enables automation of common ERP operations including document CRUD operations, webhook-triggered workflows, and synchronization with external systems. While there are limited production-ready workflow libraries specifically for ERPNext, the community has created several AI-powered templates and the technical foundation is robust.

---

## 1. Existing n8n Nodes for ERPNext

### Official ERPNext Node
- **Location**: `n8n-io/n8n/packages/nodes-base/nodes/ERPNext/ERPNext.node.ts`
- **Status**: Built-in to n8n (no additional installation required)
- **Node Type**: Action node (not a trigger node)

### Supported Operations

#### Resource: Document
The ERPNext node operates exclusively on the "Document" resource with five core operations:

1. **Get** - Retrieve a single document by DocType and name
2. **Get All** - Retrieve multiple documents with filtering and field selection
3. **Create** - Create a new document
4. **Update** - Modify an existing document (PATCH-like behavior)
5. **Delete** - Remove a document

### Dynamic Field Loading
The node provides three dynamic methods:
- `getDocTypes` - Fetches available DocTypes from `/api/resource/DocType`
- `getDocFilters` - Retrieves filterable fields for a selected DocType
- `getDocFields` - Gets all fields available for a DocType

### Key Features
- **Field Selection**: Supports selective field retrieval (including wildcard `*`)
- **Filtering**: Custom filters with operators and values
- **Pagination**: Limit support for controlled data retrieval
- **Dynamic Properties**: Field mapping for create/update operations

### API Endpoints Used
```
/api/resource/{DocType}
/api/resource/{DocType}/{DocumentName}
```

### Authentication
- Uses `erpNextApi` credential type
- Supports API Key + Secret authentication
- Credentials configured in n8n's credential manager

---

## 2. Community Templates for ERPNext Automation

### Official n8n Template Library

#### AI-Driven Lead Management and Inquiry Automation
- **Template ID**: 2758
- **URL**: https://n8n.io/workflows/2758-ai-driven-lead-management-and-inquiry-automation-with-erpnext-and-n8n/
- **Category**: Sales/CRM/AI
- **Functionality**:
  - Captures leads and inquiries through ERPNext webhooks
  - Triggers on new lead creation (DocType: Lead, trigger: on_insert)
  - Uses AI to extract key details from lead notes
  - Classifies inquiries as valid/invalid based on relevance
  - Generates automated responses
  - Integrates email notifications

#### AI-Powered Candidate Shortlisting Automation
- **Template ID**: 2757
- **URL**: https://n8n.io/workflows/2757-ai-powered-candidate-shortlisting-automation-for-erpnext/
- **Category**: HR/Recruitment
- **Functionality**:
  - Webhook for Job Applicant DocType (trigger: Insert)
  - AI-powered resume validation (Google Gemini and OpenAI)
  - Compares resumes against job descriptions
  - Updates applicant records in ERPNext
  - Custom field updates: justification, fit level, scores
  - Reduces manual HR effort

### GitHub Repositories

#### 1. enescingoz/awesome-n8n-templates
- **URL**: https://github.com/enescingoz/awesome-n8n-templates
- **Content**: Curated collection of n8n templates
- **ERPNext Content**: Includes the AI-Driven Lead Management template
- **Format**: JSON workflow files

#### 2. Zie619/n8n-workflows
- **URL**: https://github.com/Zie619/n8n-workflows
- **Scale**: 4,343 production-ready workflows, 365 unique integrations
- **ERPNext Content**: Not specifically documented, but comprehensive n8n workflow collection
- **Features**: Lightning-fast documentation system with instant search

#### 3. wassupjay/n8n-free-templates
- **URL**: https://github.com/wassupjay/n8n-free-templates
- **Scale**: 200+ plug-and-play workflows
- **Focus**: AI stack integration (vector DBs, embeddings, LLMs)
- **Usage**: Import JSON, add credentials, activate

#### 4. workflowsdiy/n8n-workflows
- **URL**: https://github.com/workflowsdiy/n8n-workflows
- **Focus**: AI-driven tasks and agentic systems
- **Content**: Diverse and powerful n8n workflows

### Limitation
**No dedicated ERPNext starter pack exists**. Available resources are individual templates rather than comprehensive workflow libraries.

---

## 3. Common Integration Patterns

### A. Webhook-Based Triggers

#### ERPNext DocType Webhooks
ERPNext can send webhooks when DocType events occur:

**Configuration**:
1. In ERPNext: Navigate to DocType settings
2. Create webhook for specific DocType (e.g., "Lead", "Job Applicant", "Sales Order")
3. Set trigger: `on_insert`, `on_update`, `on_submit`, `on_cancel`, `on_trash`
4. Configure webhook URL (n8n webhook endpoint)
5. Test with sample data

**n8n Configuration**:
1. Add Webhook node to workflow (acts as trigger)
2. Use Test URL during development
3. Use Production URL for live deployment
4. Configure authentication if required

**Example Flow**:
```
ERPNext (Lead Created) → Webhook → n8n Workflow → AI Processing → Update Lead → Email Notification
```

### B. API-Based Synchronization

#### Polling Pattern
```
Schedule Trigger (n8n) → ERPNext Get All → Filter Changes → Update External System → Update ERPNext
```

#### Push Pattern
```
External System Trigger → Transform Data → ERPNext Create/Update → Confirmation Response
```

### C. Bidirectional Data Sync

#### E-commerce Integration Pattern
```
WooCommerce/Shopify Order → n8n → Create ERPNext Sales Order → Update Inventory → Sync Back to E-commerce
```

**Common Sync Scenarios**:
- Customer data synchronization with CRMs (Salesforce, HubSpot, Pipedrive)
- Inventory sync with e-commerce platforms (WooCommerce, Shopify)
- Accounting sync (QuickBooks Online, Invoice Ninja)
- Document storage (S3, Google Drive)

### D. HTTP Request Node for Custom Operations

When built-in ERPNext node doesn't support specific operations:

**Pattern**:
1. Use HTTP Request node
2. Configure Frappe REST API endpoints
3. Authentication: Bearer token or session-based
4. Custom API calls for advanced operations

**Example Endpoints**:
```
GET  /api/resource/{DocType}
POST /api/resource/{DocType}
PUT  /api/resource/{DocType}/{name}
DELETE /api/resource/{DocType}/{name}
GET  /api/v2/document/{doctype}
POST /api/v2/document/{doctype}/{name}/method/{method}
```

### E. Authentication Patterns

#### 1. API Key + Secret (Recommended)
- Generate in ERPNext: Settings → My Settings → API Access
- Configure in n8n credentials manager
- Passed as headers in API requests

#### 2. OAuth2 Flow (Advanced)
- Three-step process: authorize → token exchange → API calls
- Bearer token authentication
- Token refresh handling

#### 3. Session-Based (Not Recommended for Automation)
- POST to `/method/login`
- Session cookie management
- Three-day validity

---

## 4. Commonly Automated ERPNext Operations

### Sales & CRM Module

#### Lead Management
- **Create Lead**: Capture from web forms, email, chat
- **Update Lead**: Qualification, scoring, assignment
- **Convert Lead**: Transform to Customer/Opportunity
- **Trigger**: `on_insert` webhook for new leads

#### Customer Operations
- **Create Customer**: Sync from CRM, e-commerce
- **Update Customer**: Address, contact, credit limit
- **Sync Customer Info**: Bidirectional CRM integration
- **Common Fields**: customer_name, customer_group, territory, email_id

#### Sales Order Automation
- **Create Sales Order**: From quotations, e-commerce orders
- **Update Status**: Track order progression
- **Generate Invoices**: Auto-invoice based on delivery
- **Material Request**: Create raw material requests from sales orders
- **Common Fields**: customer, delivery_date, items (child table), total, status

#### Quotation Processing
- **Auto-Generate**: From opportunities
- **Email Quotations**: Automated sending
- **Track Status**: Valid, expired, converted

### Purchase & Procurement

#### Purchase Order Automation
- **Create PO**: From material requests, supplier quotations
- **Supplier Notification**: Email/Slack alerts
- **Approval Workflow**: Multi-stage approvals via Slack/email
- **Status Tracking**: Draft, submitted, completed

#### Supplier Management
- **Create/Update Supplier**: Vendor onboarding
- **Scorecard Updates**: Delivery time, quality metrics
- **Invoice Processing**: Auto-prepare supplier invoices from email

#### Material Request
- **Create**: Purchase, transfer, issue, manufacture, customer-provided
- **Auto-Generate**: From sales orders, production plans
- **Common Fields**: material_request_type, schedule_date, items, warehouse

### Inventory Management

#### Item Operations
- **Create/Update Items**: Product catalog management
- **Stock Level Sync**: E-commerce platform synchronization
- **Reorder Notifications**: Low stock alerts via Slack/email
- **Common Fields**: item_code, item_name, stock_uom, item_group

#### Stock Entry
- **Material Transfer**: Warehouse to warehouse
- **Material Receipt**: From purchases
- **Material Issue**: For production
- **Stock Reconciliation**: Automated stock adjustments

### Finance & Accounting

#### Invoice Automation
- **Sales Invoice**: Auto-generate from sales orders/delivery notes
- **Purchase Invoice**: OCR from email attachments
- **Payment Entry**: Record payments automatically
- **Status Updates**: Paid, unpaid, overdue notifications

#### Payment Processing
- **Payment Reminders**: Automated email/SMS
- **Payment Reconciliation**: Match bank transactions
- **Payment Entry**: From online payment gateways

### HR & Recruitment

#### Job Applicant Processing
- **Capture Applications**: From career site, email
- **AI Resume Screening**: Automated shortlisting
- **Status Updates**: Interview scheduling, offers
- **Custom Fields**: fit_level, ai_justification, scores

#### Employee Management
- **Onboarding**: Document collection, account creation
- **Attendance**: Integration with biometric systems
- **Leave Management**: Approval workflows

### Manufacturing

#### Production Planning
- **Production Plan**: Auto-compute material requirements
- **Work Order**: Generate from sales orders
- **BOM Processing**: Material requirement explosion
- **Material Request**: Auto-create for shortfall items

### Document Management

#### General Document Operations
- **Attachment Upload**: S3, Google Drive integration
- **Document Approval**: Multi-level workflows
- **Status Tracking**: Draft, submitted, approved, cancelled
- **Comments**: Add via API (`add_comment?text=hello`)

---

## 5. Complete Workflow Libraries and Starter Packs

### Current State: Limited Availability

#### What Exists:
1. **Individual Templates**: 2 ERPNext-specific templates on n8n.io
2. **General Collections**: Large n8n workflow repositories (not ERPNext-specific)
3. **Official n8n Library**: 6,985+ community workflows (minimal ERPNext content)

#### What's Missing:
- ❌ Dedicated ERPNext starter pack
- ❌ Comprehensive ERPNext workflow library
- ❌ Industry-specific ERPNext workflows (manufacturing, retail, services)
- ❌ Complete module coverage (only sales, HR examples exist)
- ❌ Integration blueprints for common ERPNext + external system combinations

### Available Resources

#### n8n Official
- **Workflow Library**: https://n8n.io/workflows/
- **ERPNext Integration Page**: https://n8n.io/integrations/erpnext/
- **Documentation**: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.erpnext/
- **Credentials Guide**: https://docs.n8n.io/integrations/builtin/credentials/erpnext/

#### Community Forums
- **n8n Community**: https://community.n8n.io/ (search for ERPNext discussions)
- **Frappe Forum**: https://discuss.frappe.io/ (n8n integration questions)

#### Technical Documentation
- **Frappe REST API**: https://frappeframework.com/docs/user/en/api/rest
- **Unofficial API Docs**: https://github.com/alyf-de/frappe_api-docs

### Recommended Approach for Building Workflows

Given the lack of comprehensive libraries, teams should:

1. **Start with Templates**: Use the 2 available AI templates as foundations
2. **Leverage HTTP Node**: Build custom operations using Frappe REST API
3. **Document Workflows**: Export and version control as JSON
4. **Share with Community**: Contribute back to n8n workflow library
5. **Use GitHub**: Store workflows in version control (like awesome-n8n-templates)

---

## 6. ERPNext DocTypes Reference

### Commonly Automated DocTypes

#### Sales Cycle
- Lead
- Opportunity
- Quotation
- Sales Order
- Delivery Note
- Sales Invoice

#### Purchase Cycle
- Supplier
- Supplier Quotation
- Purchase Order
- Purchase Receipt
- Purchase Invoice

#### Inventory
- Item
- Stock Entry
- Material Request
- Warehouse
- Serial No
- Batch

#### Accounting
- Payment Entry
- Journal Entry
- GL Entry
- Account

#### HR
- Job Applicant
- Employee
- Attendance
- Leave Application
- Salary Slip

---

## 7. Integration Architecture Patterns

### Pattern 1: Event-Driven Automation
```
ERPNext Webhook → n8n Trigger → Business Logic → External APIs → Update ERPNext
```
**Use Cases**: Real-time lead processing, order fulfillment, approval workflows

### Pattern 2: Scheduled Synchronization
```
Cron Trigger → Fetch ERPNext Data → Transform → Sync to External System → Log Results
```
**Use Cases**: Daily inventory sync, customer data replication, report generation

### Pattern 3: Hybrid (Event + Polling)
```
Primary: Webhooks for critical events
Fallback: Scheduled polling for missed events
```
**Use Cases**: E-commerce integration, CRM sync with reconciliation

### Pattern 4: AI-Enhanced Processing
```
ERPNext Data → n8n → AI Service (OpenAI/Gemini) → Enrichment → Update ERPNext
```
**Use Cases**: Lead scoring, resume screening, invoice classification

---

## 8. Authentication Configuration

### ERPNext API Credentials Setup

1. **In ERPNext**:
   - Navigate to: Settings → My Settings → API Access
   - Click "Generate Keys"
   - Copy API Key and API Secret (shown only once)

2. **In n8n**:
   - Credentials → Add Credential → ERPNext API
   - Enter:
     - **URL**: `https://your-erpnext-instance.com`
     - **API Key**: From step 1
     - **API Secret**: From step 1
   - Test connection
   - Save

### Webhook Configuration

1. **In n8n**:
   - Add Webhook node to workflow
   - Copy webhook URL (use Production URL for live)
   - Optionally enable authentication

2. **In ERPNext**:
   - Navigate to DocType settings or create custom webhook
   - Enter n8n webhook URL
   - Select trigger event (Insert, Update, Submit, etc.)
   - Test with sample document

---

## 9. Frappe REST API Reference

### API Versions

#### v1 (Default)
- Prefix: `/api/` or `/api/v1/`
- Endpoints: `/api/resource/{DocType}`

#### v2 (Frappe v15+)
- Prefix: `/api/v2/`
- Endpoints: `/api/v2/document/{doctype}`, `/api/v2/doctype/{doctype}`
- More RESTful interface

### Common Operations

#### List Documents
```
GET /api/resource/{DocType}
Query Params: fields, filters, limit_page_length, limit_start
```

#### Get Single Document
```
GET /api/resource/{DocType}/{DocumentName}
```

#### Create Document
```
POST /api/resource/{DocType}
Body: JSON with field names and values
```

#### Update Document
```
PUT /api/resource/{DocType}/{DocumentName}
Body: JSON with fields to update (partial update supported)
```

#### Delete Document
```
DELETE /api/resource/{DocType}/{DocumentName}
```

#### Execute Method
```
POST /api/v2/document/{doctype}/{name}/method/{method}
Common methods: add_comment, submit, cancel, rename
```

### Filtering
```json
{
  "filters": [
    ["field", "operator", "value"],
    ["status", "=", "Open"],
    ["creation", ">", "2025-01-01"]
  ]
}
```

### Pagination
```
?limit_start=0&limit_page_length=20
```

---

## 10. Cost Considerations

### Pricing Comparison
- **Traditional Platforms**: ~$500+/month for 100k tasks
- **n8n Pro Plan**: Starts at ~$50/month
- **n8n Self-Hosted**: Free (infrastructure costs only)

### n8n Pricing Model
- Charges per **workflow execution** (not per task/operation)
- Single workflow with 50 nodes = 1 execution
- More cost-effective for complex workflows

---

## 11. Technical Limitations & Challenges

### Known Issues (from Community)

1. **Custom Fields**: Difficulty adding values to custom DocType fields
2. **Contact Email**: "Email Address" field not writing correctly to Contact DocType
3. **DocType Dropdown**: Occasional issues with DocType selection in n8n UI
4. **Table Fields**: Complex handling of child tables in Sales Orders and other DocTypes
5. **FrappeCloud**: Some users report connection issues with FrappeCloud instances

### Workarounds
- Use HTTP Request node for problematic operations
- Manual field mapping for custom fields
- Test with ERPNext on-premise before FrappeCloud deployment

---

## 12. Best Practices

### Workflow Design
1. **Use Webhooks for Real-Time**: Prefer webhooks over polling for time-sensitive operations
2. **Batch Operations**: Group multiple updates to reduce API calls
3. **Error Handling**: Implement retry logic and error notifications
4. **Logging**: Store execution logs for audit trails
5. **Idempotency**: Design workflows to handle duplicate executions

### Security
1. **API Keys**: Rotate regularly, never commit to version control
2. **Webhook Auth**: Enable authentication on webhook endpoints
3. **Field Selection**: Only request necessary fields (performance + security)
4. **Rate Limiting**: Respect API rate limits, implement backoff

### Performance
1. **Pagination**: Use limit_page_length for large datasets
2. **Field Filtering**: Request specific fields instead of all (`*`)
3. **Async Operations**: Use n8n's async capabilities for parallel processing
4. **Caching**: Cache frequently accessed DocType metadata

---

## 13. Next Steps for Implementation

### Phase 1: Foundation
1. Deploy n8n instance (Cloud or self-hosted)
2. Configure ERPNext API credentials
3. Test basic CRUD operations
4. Set up webhook infrastructure

### Phase 2: Core Workflows
1. Implement lead management automation
2. Configure sales order to invoice workflow
3. Set up inventory sync
4. Create customer data synchronization

### Phase 3: Advanced Integration
1. E-commerce platform integration
2. CRM bidirectional sync
3. AI-enhanced workflows
4. Custom DocType operations

### Phase 4: Observability
1. Execution logging and monitoring
2. Error alerting
3. Performance metrics
4. Workflow documentation

---

## 14. Key Resources

### Official Documentation
- **n8n ERPNext Node**: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.erpnext/
- **n8n Webhook Node**: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- **Frappe REST API**: https://frappeframework.com/docs/user/en/api/rest
- **ERPNext Docs**: https://docs.erpnext.com/

### Community
- **n8n Community Forum**: https://community.n8n.io/
- **Frappe Forum**: https://discuss.frappe.io/
- **n8n GitHub**: https://github.com/n8n-io/n8n

### Workflow Repositories
- **enescingoz/awesome-n8n-templates**: https://github.com/enescingoz/awesome-n8n-templates
- **Zie619/n8n-workflows**: https://github.com/Zie619/n8n-workflows
- **wassupjay/n8n-free-templates**: https://github.com/wassupjay/n8n-free-templates

### API Documentation
- **Unofficial Frappe API Docs**: https://github.com/alyf-de/frappe_api-docs

---

## Conclusion

n8n provides robust native integration with ERPNext through a dedicated node supporting all core CRUD operations on any DocType. While comprehensive workflow libraries are limited, the technical foundation is solid with:

- ✅ Built-in ERPNext node (no custom development needed)
- ✅ Webhook support for real-time automation
- ✅ REST API access for advanced operations
- ✅ 2 AI-powered community templates (Lead Management, HR Recruitment)
- ✅ Active community and documentation
- ✅ Cost-effective pricing model

**Gap**: No complete starter pack or comprehensive workflow library exists. Teams must build custom workflows using the ERPNext node, HTTP Request node for advanced operations, and Frappe REST API documentation.

**Recommendation**: Start with the 2 available AI templates, leverage the official ERPNext node for standard operations, use HTTP Request node for custom requirements, and contribute workflows back to the community.
