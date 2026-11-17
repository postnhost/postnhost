# Changelog

All notable changes to PostnHost are documented in this file.

## [0.2.2] - 2026-11-17

### Fixed

- Upload images in pasted article and page content through the configured CarrierWave storage, including S3-compatible destinations, instead of retaining remote image URLs or embedded base64 data. Images use the existing optimized WebP upload pipeline.
- Preserve pasted text formatting, image order, alt text, and widths. Upload every clipboard image file and avoid duplicate uploads when the clipboard contains both HTML and file representations.
- Retain surrounding text and report failed image imports without saving the original image sources.
- Protect remote image imports with authenticated endpoints, SSRF filtering, download timeouts, and a 20 MB limit.

### Upgrading existing blogs

From your host application's directory, run `bundle update postnhost` and deploy the updated application with its packaged assets. Update any exact Gemfile pin to allow PostnHost 0.2.2. No database migration or storage configuration change is required.

This release affects new pastes. Images already embedded in saved content require a separate content migration to move them into uploaded files.

## [0.2.1] - 2026-11-03

### Fixed

- Show all users' articles in the CMS article list and suggestion picker, including articles whose creator has been deleted.
- Preserve shared article suggestions when the editor displays validation errors.

## [0.2.0] - 2026-10-24

### Added

- Versioned JSON management API and Streamable HTTP MCP endpoint at `/api/v1/mcp`, relative to the engine mount path.
- 89 shared commands for CMS content, publishing, versions, uploads, translations, users, navigation, and settings, with command discovery and OpenAPI schemas.
- API & MCP dashboard for creating and revoking personal bearer tokens, with hashed token storage and one-time secret display.

### Improved

- Paginated management lists use compact summaries and bounded database queries; full content remains available through individual record commands.
- UI and management commands share translation enqueueing, preserving successfully queued work and cleaning up placeholders when enqueueing fails.

### Upgrading existing blogs

From your host application's directory, update any Gemfile constraint to allow PostnHost 0.2.0, then run:

```bash
bundle update postnhost
bin/rails postnhost:install:migrations
bin/rails db:migrate
```

Commit the copied `db/migrate/*_create_api_tokens.postnhost.rb` migration and updated schema with your application. During production deployment, run `RAILS_ENV=production bin/rails db:migrate` before restarting the app.

The new `CreateApiTokens` migration creates the `postnhost_api_tokens` table. Existing blog content requires no backfill.

## [0.1.1] - 2026-08-31

### Fixed

- Scoped packaged and host-generated CSS to PostnHost layouts and replaced competing stylesheets with one combined host build that transparently shadows the packaged logical asset.
- Corrected installer, template customization, Tailwind setup, and production checklist instructions.

## [0.1.0] - 2026-08-29

First open source release of PostnHost.

### Added

- Mountable Rails CMS engine with a built-in dashboard, onboarding, session-based authentication, and user management.
- Draft and snapshot-based publishing for articles, pages, and translated variants, including scheduled publishing, unpublishing, bulk transitions, and version restoration.
- Multilingual content, localized routes, language switching, locale-aware metadata, and optional OpenAI-assisted translations.
- Rich text editing, image uploads and processing, categories, multiple authors, article suggestions, navigation management, static pages, and site-wide settings.
- Public search, sitemaps, canonical URLs, hreflang tags, structured metadata, and HTTP and fragment caching with publication-aware invalidation.
- Three packaged public templates: Default, Swiss Editorial, and Workspace Journal.
- Generators for installation, CMS users, public view overrides, locales, static pages, and host Tailwind integration.
- Precompiled JavaScript and CSS assets with Propshaft and Sprockets support, requiring no frontend toolchain in host applications.
- Support for Ruby 3.4 and 4.0 with Rails 7.2, 8.0, and 8.1.

### Credits

Authored by Kirill Shevchenko (Ruby/Rails engineering) and Maxim Sova (technical SEO expertise).

[0.2.2]: https://github.com/postnhost/postnhost/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/postnhost/postnhost/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/postnhost/postnhost/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/postnhost/postnhost/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/postnhost/postnhost/releases/tag/v0.1.0
