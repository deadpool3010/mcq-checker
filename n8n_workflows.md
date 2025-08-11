# N8N Workflow Integration Guide

This document provides example N8N workflows that can be integrated with the MCQ Checker application.

## Prerequisites

1. N8N instance running and accessible
2. Webhook endpoints configured
3. Email/SMS services configured (optional)
4. Cloud storage configured (optional)

## Workflow Examples

### 1. Answer Key Processing Workflow

**Trigger:** Webhook - `/webhook/answer-key-uploaded`

**Workflow Steps:**
1. **Webhook Node** - Receives answer key data
2. **Set Node** - Extract relevant data
3. **Google Sheets Node** - Log answer key creation
4. **Email Node** - Send confirmation to teacher
5. **Cloud Storage Node** - Backup answer key image

**Example Webhook Payload:**
```json
{
  "event": "answer_key_uploaded",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "teacherId": "teacher_001",
    "examTitle": "Math Quiz Chapter 5",
    "totalQuestions": 50,
    "extractedAnswers": [...],
    "metadata": {...}
  }
}
```

### 2. Student Results Processing Workflow

**Trigger:** Webhook - `/webhook/student-answers-processed`

**Workflow Steps:**
1. **Webhook Node** - Receives processing results
2. **Set Node** - Calculate additional statistics
3. **Google Sheets Node** - Update results spreadsheet
4. **Conditional Node** - Check if all students processed
5. **Email Node** - Send completion notification
6. **SMS Node** - Send alerts for low scores (optional)

### 3. Report Generation Workflow

**Trigger:** Webhook - `/webhook/class-report-generated`

**Workflow Steps:**
1. **Webhook Node** - Receives report data
2. **Google Drive Node** - Upload Excel report
3. **Email Node** - Send report to teacher
4. **Slack Node** - Notify admin channel
5. **Database Node** - Log report generation

### 4. Quality Check Workflow

**Trigger:** Webhook - `/webhook/quality-check`

**Workflow Steps:**
1. **Webhook Node** - Receives quality metrics
2. **Conditional Node** - Check quality thresholds
3. **Set Node** - Format alert message
4. **Email Node** - Send quality alerts
5. **Google Sheets Node** - Log quality issues

### 5. Grade Alert Workflow

**Trigger:** Webhook - `/webhook/grade-alerts`

**Workflow Steps:**
1. **Webhook Node** - Receives student grades
2. **Split In Batches Node** - Process each student
3. **Conditional Node** - Check grade thresholds
4. **Email Node** - Send grade notifications
5. **SMS Node** - Send urgent alerts (for failing grades)

## Webhook Endpoints Configuration

### Base URL Structure
```
https://your-n8n-instance.com/webhook/[endpoint-name]
```

### Required Endpoints
- `/webhook/answer-key-uploaded`
- `/webhook/student-answers-processed`
- `/webhook/class-report-generated`
- `/webhook/quality-check`
- `/webhook/grade-alerts`
- `/webhook/backup-data`
- `/webhook/analytics-event`
- `/webhook/send-notification`

## Authentication

### API Key Authentication
```javascript
// In N8N HTTP Request Node
{
  "headers": {
    "Authorization": "Bearer YOUR_API_KEY",
    "Content-Type": "application/json"
  }
}
```

### Basic Authentication
```javascript
{
  "auth": {
    "user": "your_username",
    "password": "your_password"
  }
}
```

## Integration Examples

### Email Notifications
```javascript
// Email template for answer key confirmation
{
  "to": "{{ $json.teacherId }}@school.edu",
  "subject": "Answer Key Processed: {{ $json.examTitle }}",
  "html": `
    <h2>Answer Key Successfully Processed</h2>
    <p>Your answer key for <strong>{{ $json.examTitle }}</strong> has been processed.</p>
    <ul>
      <li>Questions detected: {{ $json.totalQuestions }}</li>
      <li>Processing time: {{ $json.timestamp }}</li>
    </ul>
    <p>You can now start adding student answer sheets.</p>
  `
}
```

### Google Sheets Integration
```javascript
// Add row to tracking spreadsheet
{
  "spreadsheetId": "your_spreadsheet_id",
  "range": "Sheet1!A:E",
  "values": [
    [
      "{{ $json.examTitle }}",
      "{{ $json.teacherId }}",
      "{{ $json.totalQuestions }}",
      "{{ $json.timestamp }}",
      "Processed"
    ]
  ]
}
```

### Slack Notifications
```javascript
{
  "channel": "#mcq-alerts",
  "text": "New exam created: {{ $json.examTitle }} by {{ $json.teacherId }}",
  "attachments": [
    {
      "color": "good",
      "fields": [
        {
          "title": "Questions",
          "value": "{{ $json.totalQuestions }}",
          "short": true
        },
        {
          "title": "Time",
          "value": "{{ $json.timestamp }}",
          "short": true
        }
      ]
    }
  ]
}
```

## Advanced Workflows

### Automated Backup Workflow
1. **Schedule Trigger** - Daily at 2 AM
2. **Database Node** - Query unsynced data
3. **Loop Node** - Process each record
4. **Cloud Storage Node** - Upload to backup location
5. **Database Node** - Mark as synced

### Performance Analytics Workflow
1. **Webhook Trigger** - Analytics events
2. **Set Node** - Process metrics
3. **InfluxDB Node** - Store time-series data
4. **Conditional Node** - Check thresholds
5. **Grafana Alert Node** - Send performance alerts

### Student Performance Tracking
1. **Webhook Trigger** - Student results
2. **Database Node** - Store historical data
3. **Function Node** - Calculate trends
4. **Conditional Node** - Detect declining performance
5. **Email Node** - Alert teachers/parents

## Error Handling

### Retry Configuration
```javascript
{
  "retries": 3,
  "retryOnFail": true,
  "waitBetween": 1000
}
```

### Error Notifications
```javascript
// On workflow error
{
  "to": "admin@school.edu",
  "subject": "MCQ Checker Workflow Error",
  "text": "Error in workflow: {{ $json.error.message }}"
}
```

## Security Best Practices

1. **Use HTTPS** for all webhook endpoints
2. **Implement API key authentication**
3. **Validate webhook payloads**
4. **Rate limit webhook endpoints**
5. **Log all webhook activities**
6. **Encrypt sensitive data**

## Monitoring and Logging

### Workflow Monitoring
- Set up alerts for failed workflows
- Monitor webhook response times
- Track processing volumes
- Log all API calls

### Health Checks
```javascript
// Health check endpoint
{
  "method": "GET",
  "url": "https://your-n8n-instance.com/webhook/health",
  "response": {
    "status": "ok",
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0.0"
  }
}
```

## Deployment Checklist

- [ ] N8N instance deployed and accessible
- [ ] Webhook endpoints configured
- [ ] Authentication set up
- [ ] Email service configured
- [ ] Cloud storage configured
- [ ] Workflows imported and activated
- [ ] Error handling configured
- [ ] Monitoring set up
- [ ] Security measures implemented
- [ ] Testing completed

## Support and Troubleshooting

### Common Issues
1. **Webhook not receiving data** - Check endpoint URL and authentication
2. **Email not sending** - Verify SMTP configuration
3. **Cloud storage errors** - Check API credentials and permissions
4. **Workflow timeouts** - Increase timeout settings

### Debug Tips
- Enable workflow execution logging
- Use debug nodes to inspect data
- Test webhooks with sample data
- Monitor N8N logs for errors

---

For more information, visit the [N8N documentation](https://docs.n8n.io/) or contact the development team.