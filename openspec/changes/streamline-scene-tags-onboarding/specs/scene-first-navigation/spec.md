## ADDED Requirements

### Requirement: Scene-first primary navigation
The system SHALL make Space/scene the first primary app experience after registration and in the main shell navigation.

#### Scenario: Registration completes
- **WHEN** a user completes avatar creation and tag selection
- **THEN** the system navigates directly to the Space scene page

### Requirement: Remove Discover and Nearby from primary tabs
The system SHALL not show Discover or Nearby as bottom navigation tabs.

#### Scenario: Main shell renders
- **WHEN** the user is inside the authenticated app shell
- **THEN** the bottom navigation contains Space, Activity, and Profile without Discover or Nearby
