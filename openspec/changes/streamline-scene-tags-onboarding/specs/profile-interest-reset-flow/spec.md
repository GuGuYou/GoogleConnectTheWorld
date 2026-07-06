## ADDED Requirements

### Requirement: Profile interest reset uses tag-selection flow
The system SHALL route profile interest changes to the onboarding-style tag-selection page instead of editing tags inline in the edit-profile page.

#### Scenario: User reselects interests from profile edit
- **WHEN** a user chooses to edit or reselect interest tags from Profile > Edit Profile
- **THEN** the system navigates to the tag-selection page and returns to Profile after saving

### Requirement: Existing profile fields remain inline editable
The system SHALL keep nickname and bio editing inside the edit-profile page.

#### Scenario: User edits nickname or bio
- **WHEN** a user opens Profile > Edit Profile
- **THEN** nickname and bio remain editable without entering the tag-selection flow
