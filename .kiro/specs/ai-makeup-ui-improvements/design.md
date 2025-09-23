# Design Document

## Overview

This design document outlines the implementation plan for improving the AI-generated makeup functionality by relocating the "おすすめメイク" button from the home screen to the diagnosis result screen, modifying the camera behavior to reuse previously captured images, and enhancing the AI makeup screen with detailed explanations and step-by-step instructions.

## Architecture

### Current Architecture Analysis

The current Flutter app follows a clean architecture pattern with feature-based organization:

- **Home Feature**: Contains Android/iOS specific home pages with the current "おすすめメイク" button
- **Diagnosis Feature**: Contains result pages that display diagnosis results with action buttons
- **Makeup Feature**: Contains AI makeup recommendation pages and providers
- **Navigation**: Uses Material Design navigation patterns with proper page transitions

### Proposed Changes

1. **Button Relocation**: Move the AI makeup button from `AndroidHomePage` to `AndroidDiagnosisResultPage`
2. **Image Reuse**: Modify the AI makeup flow to use the diagnosis image instead of launching camera
3. **Enhanced UI**: Extend the AI makeup page with reasoning and detailed steps
4. **State Management**: Ensure proper image and diagnosis data flow between screens

## Components and Interfaces

### 1. Home Screen Modifications

**File**: `client/personal_color_app/lib/features/home/presentation/android/android_home_page.dart`

**Changes**:
- Remove the "AI画像生成メイク" button from the main UI
- Remove the `_navigateToAIMakeup` method and related image picker logic
- Simplify the home screen to focus on the primary diagnosis flow

### 2. Diagnosis Result Screen Enhancements

**File**: `client/personal_color_app/lib/features/diagnosis/presentation/android/android_diagnosis_result_page.dart`

**Changes**:
- Add "おすすめメイク" button to the action buttons section
- Implement navigation to AI makeup screen with diagnosis context
- Pass the original diagnosis image and result data to the AI makeup screen

**New Method**:
```dart
void _navigateToAIMakeup(BuildContext context) {
  // Navigate to AI makeup using existing diagnosis data
}
```

### 3. AI Makeup Screen Improvements

**File**: `client/personal_color_app/lib/features/makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart`

**Enhancements**:
- Add constructor parameter to accept diagnosis result and image path
- Remove camera launching functionality
- Add reasoning section explaining why specific makeup choices were made
- Enhance step-by-step instructions with more detailed explanations
- Improve UI layout to accommodate additional content

**New Widgets**:
- `MakeupReasoningWidget`: Displays AI reasoning for makeup choices
- `DetailedStepsWidget`: Enhanced version of existing steps widget
- `DiagnosisContextWidget`: Shows connection between diagnosis and makeup recommendations

### 4. Data Flow Modifications

**Enhanced Data Models**:
- Extend `MakeupRecommendation` to include reasoning explanations
- Add diagnosis context to AI makeup requests
- Ensure image data is properly passed between screens

## Data Models

### Enhanced MakeupRecommendation

```dart
class MakeupRecommendation {
  // Existing fields...
  
  // New fields for enhanced functionality
  final String? reasoningExplanation;
  final List<DetailedMakeupStep> detailedSteps;
  final DiagnosisContext? diagnosisContext;
  
  // Constructor and methods...
}
```

### DiagnosisContext

```dart
class DiagnosisContext {
  final PersonalColorType colorType;
  final String originalImagePath;
  final DiagnosisResult diagnosisResult;
  final DateTime diagnosisTimestamp;
  
  // Constructor and methods...
}
```

### DetailedMakeupStep

```dart
class DetailedMakeupStep extends MakeupStep {
  final String reasoning;
  final List<String> tips;
  final String? videoUrl;
  final Duration? estimatedTime;
  
  // Constructor and methods...
}
```

## Error Handling

### Image Availability Validation

- Check if diagnosis image exists before navigating to AI makeup
- Display appropriate error messages if image is not available
- Provide fallback option to retake diagnosis

### Navigation Error Handling

- Implement proper error handling for navigation between screens
- Ensure graceful degradation if AI makeup service is unavailable
- Add loading states and progress indicators

## Testing Strategy

### Unit Tests

1. **Button Visibility Tests**:
   - Verify AI makeup button is not present on home screen
   - Verify AI makeup button is present on diagnosis result screen

2. **Navigation Tests**:
   - Test navigation from diagnosis result to AI makeup screen
   - Verify correct data is passed between screens

3. **Data Flow Tests**:
   - Test image data persistence and retrieval
   - Verify diagnosis context is properly maintained

### Integration Tests

1. **End-to-End Flow Tests**:
   - Complete diagnosis → view results → access AI makeup flow
   - Verify image reuse functionality works correctly

2. **UI Tests**:
   - Test enhanced AI makeup screen layout
   - Verify reasoning and detailed steps are displayed correctly

### Widget Tests

1. **Home Screen Tests**:
   - Verify AI makeup button removal
   - Test remaining functionality is unaffected

2. **Diagnosis Result Screen Tests**:
   - Test new AI makeup button integration
   - Verify button styling matches Material Design guidelines

3. **AI Makeup Screen Tests**:
   - Test enhanced content display
   - Verify reasoning and steps widgets render correctly

## Implementation Phases

### Phase 1: Button Relocation
1. Remove AI makeup button from home screen
2. Add AI makeup button to diagnosis result screen
3. Implement basic navigation without camera launch

### Phase 2: Image Reuse Implementation
1. Modify AI makeup screen to accept image parameter
2. Update navigation to pass diagnosis image
3. Remove camera picker functionality from AI makeup flow

### Phase 3: UI Enhancements
1. Add reasoning explanation section
2. Enhance step-by-step instructions
3. Improve overall layout and user experience

### Phase 4: Testing and Polish
1. Implement comprehensive test coverage
2. Perform UI/UX testing and refinements
3. Optimize performance and error handling

## Technical Considerations

### State Management
- Use existing Provider pattern for state management
- Ensure proper disposal of resources
- Maintain consistency with existing architecture

### Performance
- Optimize image loading and display
- Implement proper caching for diagnosis data
- Ensure smooth navigation transitions

### Accessibility
- Maintain accessibility compliance for all UI changes
- Ensure proper semantic labels for new buttons and content
- Test with screen readers and accessibility tools

### Platform Consistency
- Maintain Material Design 3 compliance for Android
- Ensure consistent behavior across different screen sizes
- Follow platform-specific navigation patterns