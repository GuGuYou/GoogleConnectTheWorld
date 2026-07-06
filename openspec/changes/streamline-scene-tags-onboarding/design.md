## Context

The app currently has onboarding copy partially aligned to the new message-wall concept, but the visual icon still represents offline meetups. The main shell still includes Discover and Nearby as primary tabs even though the latest direction is scene-first. Interest tag selection relies on predefined tags only, which is too coarse for fandom communities that need highly specific labels such as creator communities, CP names, exact episode references, musicians, and custom personal tags.

## Goals / Non-Goals

**Goals:**
- Make onboarding page 3 visually represent message-wall presence rather than offline meetup.
- Allow users to add custom tags in each category and as a final global custom-tag section.
- Add concrete music tags including musicians such as Jay Chou.
- Simplify bottom navigation by removing Discover and Nearby tabs and making Space/scene the first landing tab.
- Route profile interest editing to the onboarding-style tag-selection page rather than editing tags inline.

**Non-Goals:**
- Removing underlying Discover/Nearby source files or routes if other features still reference them.
- Implementing backend persistence for custom tags.
- Redesigning the full visual system beyond the affected flows.

## Decisions

- Reuse the existing `TagSelectPage` for both initial registration and profile interest reset. This avoids duplicating tag-selection UI and keeps custom tag behavior consistent.
- Represent custom tags as `IpTag` objects with generated IDs prefixed by `custom_`. This keeps matching and display code compatible with existing `IpTagChip` and user tag storage.
- Keep Discover/Nearby routes available as secondary routes but remove them from `MainShell` tabs. This reduces risk while satisfying primary navigation requirements.
- Change the shell branch order to Space first, then Activity, then Profile. Login/tag completion should navigate to `/space`.
- Profile edit should expose a “reselect interests” entry that navigates to `/tag-select?return=/profile`; inline tag editing should be removed or hidden.

## Risks / Trade-offs

- Custom tags are local-only in the mock data source → acceptable for prototype; later backend persistence can store custom tags by user ID.
- Removing primary Discover/Nearby tabs may leave some routes unused → routes stay available to avoid breaking deep links during transition.
- Reusing `TagSelectPage` for profile reset requires return-location support → add query parameter handling and default to `/space` for registration.
