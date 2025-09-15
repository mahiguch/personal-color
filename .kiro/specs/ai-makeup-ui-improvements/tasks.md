# Implementation Plan

- [x] 1. Remove AI makeup button from home screen
  - Remove the "AI画像生成メイク" button and related UI elements from AndroidHomePage
  - Remove the `_navigateToAIMakeup` method and image picker logic
  - Clean up imports and unused dependencies
  - _Requirements: 1.3_

- [x] 2. Add AI makeup button to diagnosis result screen
  - Add "AI生成メイク" button to the action buttons section in AndroidDiagnosisResultPage
  - Implement proper Material Design 3 styling consistent with existing buttons
  - Position the button appropriately in the UI layout
  - _Requirements: 1.1, 1.2_

- [x] 3. Implement navigation from diagnosis result to AI makeup screen
  - Create `_navigateToAIMakeup` method in AndroidDiagnosisResultPage
  - Pass diagnosis result data and original image path to AI makeup screen
  - Ensure proper error handling for missing image data
  - _Requirements: 1.2, 2.3_

- [x] 4. Modify AI makeup screen to accept diagnosis context
  - Update AIMakeupRecommendationPageV3 constructor to accept diagnosis result and image path
  - Remove camera launching functionality and image picker logic
  - Update the screen to use provided image instead of launching camera
  - _Requirements: 2.1, 2.2_

- [x] 5. Enhance data models for improved AI makeup functionality
  - Extend MakeupRecommendation class to include reasoning explanations
  - Create DiagnosisContext class to encapsulate diagnosis information
  - Update DetailedMakeupStep to include additional explanation fields
  - _Requirements: 3.1, 3.2, 4.1, 4.2_

- [x] 6. Create reasoning explanation widget
  - Implement MakeupReasoningWidget to display AI reasoning for makeup choices
  - Connect reasoning to user's specific personal color type
  - Ensure proper styling and layout integration
  - _Requirements: 3.1, 4.3_

- [x] 7. Enhance makeup steps widget with detailed instructions
  - Extend existing MakeupStepsWidget to show more detailed explanations
  - Add reasoning for each step based on personal color analysis
  - Organize steps in logical application order
  - _Requirements: 3.2, 3.4_

- [x] 8. Update AI makeup provider to handle diagnosis context
  - Modify AIMakeupRecommendationProvider to accept and use diagnosis context
  - Update API calls to include personal color type information
  - Ensure proper error handling for context validation
  - _Requirements: 4.1, 4.2_

- [x] 9. Implement comprehensive error handling
  - Add validation for image availability before navigation
  - Display appropriate error messages for missing diagnosis data
  - Provide fallback options when AI makeup is not available
  - _Requirements: 2.3_

- [x] 10. Create unit tests for button relocation
  - Write tests to verify AI makeup button is removed from home screen
  - Test that AI makeup button appears on diagnosis result screen
  - Verify button styling and behavior
  - _Requirements: 1.1, 1.3_

- [x] 11. Create integration tests for navigation flow
  - Test complete flow from diagnosis result to AI makeup screen
  - Verify correct data passing between screens
  - Test error scenarios and edge cases
  - _Requirements: 1.2, 2.1, 2.2_

- [x] 12. Create widget tests for enhanced AI makeup screen
  - Test reasoning widget display and content
  - Verify enhanced steps widget functionality
  - Test layout and styling of new components
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 13. Update iOS implementation for consistency
  - Apply similar changes to iOS diagnosis result page if needed
  - Ensure consistent behavior across platforms
  - Update iOS-specific navigation patterns
  - _Requirements: 1.1, 1.2_

- [x] 14. Perform end-to-end testing and optimization
  - Test complete user journey from diagnosis to AI makeup
  - Optimize performance and loading times
  - Verify accessibility compliance
  - _Requirements: 3.3, 4.3_

- [x] 15. Update documentation and finalize implementation
  - Update code comments and documentation
  - Verify all requirements are met
  - Perform final code review and cleanup
  - _Requirements: All requirements_