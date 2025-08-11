# MCQ Checker - Complete Setup Guide

This guide will help you set up and run the MCQ Checker application from scratch.

## 📋 Prerequisites

### System Requirements
- **Flutter SDK**: 3.8.1 or higher
- **Dart SDK**: Included with Flutter
- **Android Studio** or **VS Code** with Flutter extensions
- **Android device/emulator** or **iOS device/simulator**

### API Requirements
- **OpenAI API Key**: Required for AI-powered answer recognition
- **N8N Instance**: Optional for workflow automation
- **Firebase Project**: Optional for cloud sync

## 🚀 Installation Steps

### 1. Clone and Setup Project

```bash
# Clone the repository
git clone <repository-url>
cd mcqchecker

# Install Flutter dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

### 2. Configure Development Environment

#### Android Setup
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Connect Android device or start emulator
flutter devices
```

#### iOS Setup (macOS only)
```bash
# Install iOS dependencies
cd ios
pod install
cd ..

# Open iOS simulator
open -a Simulator
```

### 3. Get API Keys

#### OpenAI API Key
1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Create an account or sign in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (starts with `sk-`)

#### N8N Setup (Optional)
1. Deploy N8N instance:
   - **Self-hosted**: Follow [N8N installation guide](https://docs.n8n.io/getting-started/installation/)
   - **Cloud**: Use [N8N Cloud](https://n8n.cloud/)
2. Configure webhook endpoints
3. Import workflows from `n8n_workflows.md`

### 4. Run the Application

```bash
# Run on connected device/emulator
flutter run

# Run in debug mode
flutter run --debug

# Run in release mode (for testing performance)
flutter run --release
```

## ⚙️ Configuration

### 1. Initial App Configuration

When you first run the app:

1. **Setup API Configuration Dialog** will appear
2. Enter your **OpenAI API Key** (required)
3. Enter your **N8N Base URL** (optional)
4. Enter your **N8N API Key** (optional)
5. Tap **Initialize**

### 2. Settings Configuration

Access settings through the app:

1. Open the app
2. Tap the **Settings** icon in the top-right
3. Configure:
   - API Keys
   - Teacher Information
   - Processing Settings
   - Data Management options

### 3. Environment Variables (Optional)

Create a `.env` file in the project root:

```env
OPENAI_API_KEY=your_openai_api_key_here
N8N_BASE_URL=https://your-n8n-instance.com
N8N_API_KEY=your_n8n_api_key_here
```

## 📱 Using the Application

### 1. Create Your First Exam

1. **Launch the app** and complete initial setup
2. **Tap "New Exam"** button
3. **Fill in exam details**:
   - Exam title (e.g., "Math Quiz Chapter 5")
   - Number of questions (default: 50)
   - Answer format (default: A,B,C,D)
4. **Select image source** (Camera or Gallery)
5. **Take/select answer key photo**
6. **Tap "Process Answer Key"**
7. **Wait for AI processing** to complete

### 2. Add Student Answer Sheets

1. **Select your exam** from the home screen
2. **Tap "Add Students"** button
3. **Select multiple student images** from gallery or take photos
4. **Enter student names** for each image
5. **Wait for processing** to complete
6. **View results** in the Students tab

### 3. Generate Reports

1. **Go to exam results screen**
2. **Tap the menu** (three dots)
3. **Select "Generate Report"**
4. **Choose report format** (Excel/PDF)
5. **Reports saved** to device storage
6. **Share or export** as needed

## 🔧 Troubleshooting

### Common Issues

#### 1. API Key Errors
```
Error: Invalid OpenAI API key
```
**Solution**: 
- Verify API key is correct
- Check API key has sufficient credits
- Ensure key has GPT-4 Vision access

#### 2. Image Processing Errors
```
Error: Failed to process image
```
**Solutions**:
- Ensure good image quality (clear, well-lit)
- Check image contains visible answers
- Try different image format or quality

#### 3. Permission Errors
```
Error: Camera/Storage permission denied
```
**Solutions**:
- Grant camera permission in device settings
- Grant storage permission for file access
- Restart app after granting permissions

#### 4. Network Connectivity
```
Error: Network request failed
```
**Solutions**:
- Check internet connection
- Verify API endpoints are accessible
- Check firewall settings

### Debug Mode

Enable debug logging:

```bash
# Run with verbose logging
flutter run --verbose

# View device logs
flutter logs
```

### Performance Issues

If the app is slow:

1. **Check device specifications** (minimum 2GB RAM recommended)
2. **Reduce image quality** in settings
3. **Process fewer images** at once
4. **Clear app cache** in device settings
5. **Restart the app**

## 🚀 Advanced Configuration

### 1. Firebase Integration (Optional)

For cloud sync and backup:

1. **Create Firebase project**
2. **Add Android/iOS apps**
3. **Download configuration files**:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. **Enable Firestore and Storage**
5. **Update security rules**

### 2. Custom N8N Workflows

1. **Import workflows** from `n8n_workflows.md`
2. **Configure webhook URLs** in app settings
3. **Set up email/SMS services** in N8N
4. **Test workflow triggers**

### 3. Batch Processing Optimization

For large classes:

```dart
// Adjust batch size in settings
const int BATCH_SIZE = 10; // Process 10 images at once
const double IMAGE_QUALITY = 0.7; // Reduce quality for faster processing
const int MAX_RETRIES = 2; // Reduce retries for faster processing
```

## 📊 Monitoring and Analytics

### 1. Usage Analytics

Track app usage:
- Number of exams created
- Images processed
- Error rates
- Processing times

### 2. Quality Metrics

Monitor AI accuracy:
- Confidence scores
- Manual corrections needed
- Success rates by image quality

### 3. Performance Metrics

Track performance:
- Processing speed
- Memory usage
- Battery consumption
- Network usage

## 🔐 Security Best Practices

### 1. API Key Security
- Store API keys securely
- Rotate keys regularly
- Monitor API usage
- Set usage limits

### 2. Data Privacy
- Store data locally by default
- Encrypt sensitive information
- Implement data retention policies
- Provide data export/deletion

### 3. Network Security
- Use HTTPS for all API calls
- Validate server certificates
- Implement request signing
- Rate limit API calls

## 📈 Scaling for Large Deployments

### 1. School/District Deployment

For multiple teachers:
- Set up centralized N8N instance
- Configure shared cloud storage
- Implement user authentication
- Set up admin dashboard

### 2. Performance Optimization

For high volume:
- Implement image compression
- Use CDN for static assets
- Cache frequently accessed data
- Optimize database queries

### 3. Infrastructure Scaling

For large scale:
- Use load balancers
- Implement horizontal scaling
- Set up monitoring and alerting
- Plan for disaster recovery

## 📞 Support and Resources

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [N8N Documentation](https://docs.n8n.io/)

### Community Support
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub Issues](https://github.com/your-repo/issues)

### Professional Support
- Email: support@mcqchecker.com
- Documentation: docs.mcqchecker.com
- Training: training@mcqchecker.com

## 🎯 Next Steps

After successful setup:

1. **Test with sample answer sheets**
2. **Train teachers on app usage**
3. **Set up backup procedures**
4. **Monitor system performance**
5. **Plan for scaling needs**

---

**Congratulations!** 🎉 Your MCQ Checker application is now ready to revolutionize your assessment process. Start with small tests and gradually scale up as you become more comfortable with the system.