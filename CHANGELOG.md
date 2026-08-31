# Changelog

All notable changes to PostnHost are documented in this file.

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

[0.1.1]: https://github.com/postnhost/postnhost/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/postnhost/postnhost/releases/tag/v0.1.0
