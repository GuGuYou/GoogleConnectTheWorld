## Why

Current onboarding and navigation no longer match the product direction: the app should center on a scene-first experience, message-wall encounters, and highly specific self-defined interest tags rather than generic discovery/nearby tabs.

## What Changes

- Update onboarding page 3 icon and meaning from offline meetup to message wall.
- Extend interest tag selection to support custom tags in every category and as a final free-form option.
- Add more concrete music examples such as Jay Chou and other musicians.
- **BREAKING**: Remove the Discover and Nearby bottom tabs from the primary app structure.
- Make the post-registration landing experience show the Space/scene directly.
- Change Profile > Edit Profile interest editing so users return to the tag-selection flow instead of editing tags inline.

## Capabilities

### New Capabilities
- `custom-interest-tags`: Supports category-level and global custom interest tags during onboarding/tag selection.
- `scene-first-navigation`: Defines the primary app navigation with Space/scene as the entry experience and no Discover/Nearby tabs.
- `message-wall-onboarding`: Aligns onboarding copy/iconography with the message-wall product concept.
- `profile-interest-reset-flow`: Lets users reselect or customize interests from the onboarding-style tag flow via profile editing.

### Modified Capabilities


## Impact

- `lib/features/onboarding/onboarding_page.dart`
- `lib/features/auth/tag_select_page.dart`
- `lib/shared/models/ip_tag.dart`
- `lib/shared/data/mock_data_source.dart`
- `lib/shared/data/repositories.dart`
- `lib/core/router/app_router.dart`
- `lib/shared/widgets/main_shell.dart`
- `lib/features/profile/edit_profile_page.dart`
- `lib/core/l10n/app_text.dart`
