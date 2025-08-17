# Disaster Recovery Plan - Personal Color Diagnosis API

## Overview

This document outlines the disaster recovery procedures for the Personal Color Diagnosis API deployed on Google Cloud Platform.

## Architecture Overview

- **Primary Region**: us-central1
- **Service**: Cloud Run (personal-color-api)
- **Container Registry**: Google Container Registry (GCR)
- **AI Service**: Vertex AI (Gemini)
- **Monitoring**: Google Cloud Monitoring

## Backup Strategy

### 1. Container Images
- **Automatic**: GCR maintains image versions automatically
- **Retention**: Keep last 10 versions
- **Location**: Multi-regional storage

### 2. Configuration
- **Source Code**: GitHub repository (primary backup)
- **Environment Variables**: Documented in `.env.production` template
- **Service Configuration**: `cloudrun-service.yaml` in repository

### 3. Logs
- **Automatic**: Cloud Logging with 30-day retention
- **Export**: Automated daily export to Cloud Storage
- **Long-term**: 1-year retention in cold storage

## Recovery Procedures

### 1. Service Outage (Cloud Run)

#### Symptoms
- Health check endpoints failing
- High error rates (>10%)
- Service unavailable

#### Immediate Response (< 5 minutes)
1. Check service status:
   ```bash
   gcloud run services describe personal-color-api --region=us-central1
   ```

2. Check recent deployments:
   ```bash
   gcloud run revisions list --service=personal-color-api --region=us-central1
   ```

3. Rollback to previous version if needed:
   ```bash
   gcloud run services update-traffic personal-color-api \
     --to-revisions=PREVIOUS_REVISION=100 \
     --region=us-central1
   ```

#### Investigation (< 15 minutes)
1. Check Cloud Monitoring dashboards
2. Review Cloud Logging for errors
3. Check Vertex AI service status
4. Verify network connectivity

#### Full Recovery (< 30 minutes)
1. Redeploy from source:
   ```bash
   cd /path/to/server
   ./deploy.sh production YOUR_PROJECT_ID
   ```

2. Verify health endpoints:
   ```bash
   curl https://your-service-url/health
   curl https://your-service-url/health/detailed
   ```

### 2. Regional Disaster

#### Multi-Region Deployment Setup
```bash
# Deploy to secondary region
gcloud run deploy personal-color-api \
  --image gcr.io/PROJECT_ID/personal-color-api:latest \
  --region us-east1 \
  --platform managed

# Set up load balancer for traffic distribution
gcloud compute url-maps create personal-color-lb \
  --default-service personal-color-backend-us-central1

gcloud compute backend-services create personal-color-backend-us-central1 \
  --global \
  --load-balancing-scheme=EXTERNAL
```

#### DNS Failover
1. Update DNS records to point to secondary region
2. Monitor traffic distribution
3. Coordinate with Flutter app updates if needed

### 3. Complete Infrastructure Loss

#### Recovery Steps
1. **Restore from GitHub**:
   ```bash
   git clone https://github.com/your-org/personal-color.git
   cd personal-color/server
   ```

2. **Set up new GCP project**:
   ```bash
   gcloud projects create personal-color-recovery
   ./deploy.sh production personal-color-recovery
   ```

3. **Update DNS and Flutter app configuration**

4. **Restore monitoring and alerting**

## Monitoring and Alerting

### Critical Alerts

#### 1. Service Down
- **Condition**: Health check failures for >2 minutes
- **Action**: Immediate notification to on-call engineer
- **Auto-response**: Attempt automatic restart

#### 2. High Error Rate
- **Condition**: Error rate >5% for >5 minutes
- **Action**: Alert development team
- **Auto-response**: Scale up instances

#### 3. High Latency
- **Condition**: P95 response time >10 seconds for >5 minutes
- **Action**: Performance investigation required
- **Auto-response**: Scale up resources

#### 4. Vertex AI Issues
- **Condition**: AI service errors >20% for >2 minutes
- **Action**: Check Google Cloud Status page
- **Auto-response**: Implement circuit breaker

### Monitoring Setup Commands

```bash
# Create notification channel
gcloud alpha monitoring channels create \
  --display-name="Personal Color API Alerts" \
  --type=email \
  --channel-labels=email_address=alerts@yourdomain.com

# Create alerting policies
gcloud alpha monitoring policies create \
  --policy-from-file=monitoring/alert-policies.yaml
```

## Communication Plan

### Internal Communication
1. **Incident Commander**: Lead developer
2. **Technical Lead**: Senior engineer
3. **Stakeholders**: Product manager, QA team

### External Communication
1. **Users**: In-app error messages
2. **Status Page**: Update service status
3. **Social Media**: For extended outages

### Communication Templates

#### Service Degradation
```
🔧 We're experiencing some technical difficulties with our Personal Color Diagnosis service. 
Our team is working to resolve the issue. Thank you for your patience.
Estimated resolution: [TIME]
```

#### Service Restored
```
✅ Our Personal Color Diagnosis service has been fully restored. 
Thank you for your patience during the temporary disruption.
```

## Testing and Validation

### Monthly DR Tests
1. **Failover Test**: Switch to secondary region
2. **Recovery Test**: Full redeployment from source
3. **Data Integrity**: Verify service functionality
4. **Performance**: Validate response times

### Quarterly Reviews
1. Update recovery procedures
2. Review and update contact information
3. Test communication channels
4. Update documentation

## Security Considerations

### During Recovery
1. **Access Control**: Verify proper IAM permissions
2. **Secrets Management**: Rotate API keys if compromised
3. **Network Security**: Ensure VPC and firewall rules
4. **Audit Trail**: Log all recovery actions

### Post-Incident
1. **Security Scan**: Full vulnerability assessment
2. **Access Review**: Audit who had access during incident
3. **Compliance**: Ensure regulatory requirements met

## Contact Information

### On-Call Rotation
- **Primary**: [Engineer Name] - [Phone] - [Email]
- **Secondary**: [Engineer Name] - [Phone] - [Email]
- **Escalation**: [Manager Name] - [Phone] - [Email]

### External Contacts
- **Google Cloud Support**: [Support Case URL]
- **DNS Provider**: [Contact Information]
- **CDN Provider**: [Contact Information]

## Metrics and SLAs

### Service Level Objectives (SLOs)
- **Availability**: 99.9% uptime
- **Latency**: 95% of requests < 5 seconds
- **Error Rate**: < 1% error rate

### Recovery Time Objectives (RTOs)
- **Minor Issues**: < 15 minutes
- **Major Outages**: < 1 hour
- **Regional Disaster**: < 4 hours
- **Complete Infrastructure Loss**: < 24 hours

### Recovery Point Objectives (RPOs)
- **Configuration**: No data loss (stored in Git)
- **Logs**: Up to 15 minutes of loss acceptable
- **User Data**: Not applicable (stateless service)

## Documentation Updates

This document should be reviewed and updated:
- After each incident
- Monthly during DR tests
- Quarterly during reviews
- When architecture changes

Last Updated: [DATE]
Document Version: 1.0