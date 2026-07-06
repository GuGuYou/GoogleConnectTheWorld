## ADDED Requirements

### Requirement: Category-level custom interest tags
The system SHALL allow users to add custom interest tags while selecting tags within each category including games, anime, dramas, comics, and music.

#### Scenario: Add custom tag inside category
- **WHEN** a user enters a custom tag in a category and confirms it
- **THEN** the system adds the custom tag to the selected tags for that category and displays it as a selectable chip

### Requirement: Global custom interest tags
The system SHALL provide a final custom tag section for any tag that does not fit predefined categories.

#### Scenario: Add final custom tag
- **WHEN** a user enters a custom tag in the final custom section and confirms it
- **THEN** the system adds it to the selected tags and counts it toward the minimum selected tag requirement

### Requirement: Specific fandom tag examples
The system SHALL include examples or presets that support highly specific fandom labels such as creator communities, exact show names, episode-level references, CP names, and concrete musicians.

#### Scenario: Music category includes musician examples
- **WHEN** the user views the music tag category
- **THEN** the system includes concrete musician examples such as Jay Chou
