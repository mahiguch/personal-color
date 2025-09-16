# Requirements Document

## Introduction

This feature involves improving the AI-generated makeup functionality by relocating the "AI生成メイク" (AI Generated Makeup) button from the home screen to the diagnosis result screen, modifying the camera behavior to use previously captured images instead of launching the camera, and enhancing the AI makeup screen with additional information such as reasoning and makeup steps.

## Requirements

### Requirement 1

**User Story:** As a user who has completed a personal color diagnosis, I want to access the AI makeup feature directly from my diagnosis results, so that I can easily apply makeup recommendations based on my diagnosed color type.

#### Acceptance Criteria

1. WHEN the user is on the diagnosis result screen THEN the system SHALL display an "AI生成メイク" button
2. WHEN the user taps the "AI生成メイク" button on the diagnosis result screen THEN the system SHALL navigate to the AI makeup screen
3. WHEN the user is on the home screen THEN the system SHALL NOT display the "AI生成メイク" button

### Requirement 2

**User Story:** As a user who wants to generate AI makeup, I want the system to use my previously captured diagnosis image, so that I don't need to take another photo and can maintain consistency with my diagnosis.

#### Acceptance Criteria

1. WHEN the user taps the "AI生成メイク" button THEN the system SHALL NOT launch the camera
2. WHEN the user accesses the AI makeup feature THEN the system SHALL use the image from the previous diagnosis session
3. WHEN no previous diagnosis image is available THEN the system SHALL display an appropriate error message and guide the user to complete a diagnosis first

### Requirement 3

**User Story:** As a user viewing AI-generated makeup recommendations, I want to see detailed explanations and step-by-step instructions, so that I can understand why certain makeup choices were made and how to apply them.

#### Acceptance Criteria

1. WHEN the AI makeup screen is displayed THEN the system SHALL show the reasoning behind the makeup recommendations
2. WHEN the AI makeup screen is displayed THEN the system SHALL provide step-by-step makeup application instructions
3. WHEN the AI makeup screen is displayed THEN the system SHALL present the information in a clear, readable format
4. WHEN the user views the makeup steps THEN the system SHALL organize them in logical application order (e.g., base, eyes, lips)

### Requirement 4

**User Story:** As a user, I want the AI makeup feature to be contextually integrated with my diagnosis results, so that the makeup recommendations are personalized to my specific color analysis.

#### Acceptance Criteria

1. WHEN generating AI makeup THEN the system SHALL use the user's diagnosed personal color type as input
2. WHEN displaying makeup recommendations THEN the system SHALL reference the user's specific color season (Spring, Summer, Autumn, Winter)
3. WHEN showing makeup reasoning THEN the system SHALL explain how the recommendations align with the user's personal color characteristics