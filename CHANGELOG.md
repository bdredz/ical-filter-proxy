# Changelog

All notable changes to this fork are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Everything before
1.0.0 is the upstream [darkphnx/ical-filter-proxy](https://github.com/darkphnx/ical-filter-proxy).

When releasing: add a section here, bump `IcalFilterProxy::VERSION` in
`lib/ical_filter_proxy/version.rb` to match (a spec enforces this), merge to
`master`, then tag the merge commit `vX.Y.Z`.

## [1.1.3] - 2026-10-02

### Added
- `CHANGELOG.md` and `IcalFilterProxy::VERSION`, with a spec that keeps them in sync.
- README section for the Gwinnett calendar: live links, Vercel deployment and
  the yearly update checklist.

## [1.1.2] - 2026-10-02

### Changed
- Landing page title is now "Gwinnett School Calendar" with "2026-27" centered
  beneath it. The first line fits on one line from 320px wide screens up.
- Subscribe step 4 now says to tap the checkmark, matching the iOS screen.
- Feed calendar name (`X-WR-CALNAME`) is now "Gwinnett School Calendar 2026-27".

## [1.1.1] - 2026-10-02

### Changed
- Landing page shows numbered iPhone subscribe steps first, before the buttons.

## [1.1.0] - 2026-10-01

### Added
- `public/index.html` subscribe page with a `webcal://` button for iPhone/Mac,
  an Add to Google Calendar link and a copy-link button. It is marked unofficial.
- Optional `name` config, which sets `X-WR-CALNAME` so subscribers see a
  calendar name instead of the URL.

## [1.0.0] - 2026-09-30

### Added
- `gwinnett-school` calendar in `config.yml`. An allowlist over the GCPS
  district feed keeps school-specific events (first/last day, early release,
  digital learning days, semester boundaries, planning days, school breaks,
  100th day) and drops general holidays, board meetings and observances.
- Optional `extra_events` config, which appends all-day events the source feed
  is missing (used for the Jan 4, 2027 student holiday). UIDs are stable and
  events are rebuilt per request so alarms never accumulate.
- Vercel deployment: `vercel.json` with zero-config `/api` function and a
  `/gwinnett-school.ics` rewrite.
- Regression spec against a snapshot of the live feed that asserts the exact
  dates from the official 2026-27 GCPS calendar.

### Changed
- `config.yml` is now tracked so deployments can read it.
- YAML config accepts unquoted dates.

### Security
- Static output is limited to `public/`. Repo files such as `config.yml` and
  `lib/` are no longer served publicly. A disallow-all `robots.txt` was added.

[1.1.3]: https://github.com/bdredz/ical-filter-proxy/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/bdredz/ical-filter-proxy/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/bdredz/ical-filter-proxy/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/bdredz/ical-filter-proxy/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/bdredz/ical-filter-proxy/compare/8654140...v1.0.0
