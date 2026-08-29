# CMS Architecture

PostnHost is an isolated, mountable Rails engine that provides a single-site publishing system inside a host application. Its central architectural rule is that editable CMS records and publicly visible records are separate: editors work on drafts, while public requests read publication snapshots.

The engine owns CMS behavior, public rendering, publishing workflows, translations, generators, migrations, packaged assets, and engine-specific authentication. The host application owns the runtime around it: the database, cache and job adapters, deployment, backups, monitoring, credentials, storage configuration, and any application-wide security policy.

## Runtime boundary

The engine is mounted at an arbitrary path, commonly `/blog`, and isolates the `Postnhost` namespace. Public URL generation, canonical URLs, cache keys, and sitemap paths account for the mount point through `request.script_name`.

| Engine responsibility | Host responsibility |
| --- | --- |
| CMS and public routes, controllers, models, views, helpers, and services | Mount path and surrounding application routes |
| Installable migrations and namespaced tables | Database engine, persistence, backup, and restore |
| Active Job classes and publishing schedules | Active Job adapter and worker processes |
| CarrierWave uploaders and generated storage configuration | Storage provider, credentials, and lifecycle policy |
| Packaged JavaScript, CSS, images, and public templates | Asset pipeline, optional host Tailwind build, and view overrides |
| Built-in CMS sessions and onboarding | Application-wide middleware, CSP, rate limits, proxy trust, and monitoring |

`Postnhost::ApplicationController` inherits from the host application's `::ApplicationController`. Host-wide controller behavior therefore remains part of the runtime contract, while engine controllers add PostnHost authentication, timezone, helpers, and CMS behavior.

## Request surfaces

The engine serves four kinds of work:

- **Public requests** render published articles, pages, categories, authors, search results, static pages, and sitemaps. They do not authenticate, except for draft previews.
- **CMS requests** manage drafts, translations, categories, languages, navigation, templates, users, settings, and publication transitions. They require a PostnHost session.
- **Onboarding and sessions** create the first CMS user, establish the initial site configuration, and provide subsequent sign-in and sign-out.
- **Background jobs** publish scheduled articles and generate optional OpenAI-backed translations through the host application's Active Job adapter.

The engine is single-site rather than tenant-scoped. `Setting`, `Template`, and `PublicSiteRevision` are singleton records for the installed PostnHost site.

## Domain model

Articles and pages are the editable primary-language records. Their language variants hold translated draft fields. Categories group articles, users can be attached as ordered authors, and article suggestions can be ordered manually. Navigation and site settings control the public shell.

The public projection mirrors only the state that readers are allowed to see:

| Draft side | Public side |
| --- | --- |
| `Article` | `Snapshot::Article` |
| `ArticleVariant` | `Snapshot::ArticleVariant` |
| `Page` | `Snapshot::Page` |
| `PageVariant` | `Snapshot::PageVariant` |
| `ArticleCategory` relationships | `Snapshot::ArticleCategory` relationships |
| `ArticleAuthor` relationships | `Snapshot::ArticleAuthor` relationships |
| `ArticleSuggestion` relationships | `Snapshot::ArticleSuggestion` relationships |

Categories, category translations, languages, author profiles, settings, templates, navigation, and site scripts are live configuration records rather than snapshot copies. Changes to visitor-visible configuration increment the public-site revision so public responses and fragments revalidate.

## Snapshot semantics

Articles, pages, and their language variants are editable drafts. Publishing copies the current draft fields and public relationships into a dedicated public snapshot. Public controllers, route resolution, search, SEO, suggestions, sitemap generation, and fragment caches read those snapshots. Editing a draft does not change the live site until the draft is published again.

A snapshot row is the current public projection, not an append-only event. First publication creates it; republishing replaces its copied fields and relationships in place while preserving its original `published_at`. Each publication also records the source draft as a PaperTrail version and points the snapshot at that version.

Unpublishing removes the base snapshot but keeps the draft and any variant snapshots. Public variant queries join through the base snapshot, so variants are hidden while their parent is unpublished and become visible again when the parent is republished. A variant can also be unpublished independently by removing only its own snapshot.

PaperTrail records published moments rather than every autosave or draft edit. Restoring a version changes only the draft. Editors review that restored draft and publish it through the regular publication workflow when it is ready to replace the public snapshot.

Cover-image identifiers are copied into article snapshots. The cover-image uploader retains previously stored files, and `PublishedCoverImage` reconstructs the public uploader from the snapshot identifier. Storage cleanup must account for current snapshots and historical PaperTrail versions instead of assuming that replacing a draft upload makes the previous file disposable.

## Publication workflow

Manual, scheduled, bulk, and variant publication converge on services under `Postnhost::Publishing`:

```text
CMS controller or Active Job
  -> publish/unpublish service
  -> Revision.hold transaction and singleton row lock
  -> draft row lock
  -> validation and route-conflict checks
  -> PaperTrail publication version
  -> snapshot fields and relationships
  -> one public-site revision increment
  -> commit
```

`Publishing::Revision.hold` serializes publication transitions on the singleton revision row. Nested publication calls join the existing hold, so a bulk transition increments the public revision once rather than once per record. An exception escaping the outer hold rolls back both snapshot changes and the revision increment.

Article publication validates required content and route availability, captures a PaperTrail version, writes scalar fields and the cover-image identifier, replaces snapshot category/author/suggestion joins, and clears completed scheduling state. Page and variant publishers follow the same smaller pattern. A variant cannot be published until its base article or page has a snapshot.

Bulk variant transitions use one outer revision hold and a savepoint per record. Successful records remain committed together, individual failures are reported, and the batch still represents one public revision.

Scheduled articles store both the requested time and the enqueued Active Job ID. The scheduled publisher verifies that the article is due and that the executing job still matches the stored ID before it writes a snapshot. Rescheduling or unscheduling invalidates the previous job identity.

Published slugs are validated against other article and page snapshots, categories, code-defined static pages, and reserved engine routes. Drafts may temporarily contain conflicting slugs; publication is the boundary that must reject an ambiguous public route.

## Public request flow

`PublicRequestContext` is memoized in the Rack request environment and provides the setting, selected template, public revision, requested language, and public route resolution. Ambiguous slugs are resolved in this order:

1. category;
2. article snapshot;
3. page snapshot.

The default language uses unprefixed routes. Non-default languages use `/:locale` routes and are available only when a matching variant snapshot exists. Joining variant snapshots through their base snapshot enforces the parent-publication rule at query time.

Public controllers apply conditional HTTP caching before loading article collections or render-heavy associations. Once a response is stale, controllers load snapshot scopes, localized variants, author/category relationships, navigation data, and the selected public template. Draft preview is the deliberate exception: it requires authentication and renders editable records.

Search queries snapshot title, content, and metadata. Suggestions start with the ordered relationships copied into the article snapshot, then fill any remaining slots from published articles in related categories. Sitemap generation likewise reads snapshots and emits localized alternates only for published variants.

## Caching and invalidation

`PublicSiteRevision` is the global invalidation boundary for visitor-visible state. Publishing services increment it transactionally; live public configuration models use `PublicRevisionTouch` or touch a parent setting that does.

Public ETags include the layout digest, public revision, language, controller/action, mount path, relevant setting values, and resource-specific dependencies. Responses use `must-revalidate`, allowing unchanged requests to return `304 Not Modified`. Signed-in requests bypass shared public HTTP caching.

Fragment caches include the public revision where their output depends on site-wide public state. Navigation caches are keyed by revision and language. The sitemap cache includes the public revision, canonical origin, mount path, and a signature of code-defined static-page templates.

The revision makes old cache entries unreachable; normal cache eviction reclaims them. Publication code should not manually expire public fragments.

## Internationalization

`Language` records determine available content languages and the one default language. Article, page, and category variants belong to non-default languages. Public route locale selection sets `I18n.locale`, while engine locale files provide public interface copy under `postnhost.public`.

Settings may store runtime locale overrides. The engine's I18n backend patch checks those overrides before falling back to host and engine locale files. Host applications using multiple locales must configure English, or another explicit mapping, as the fallback target.

AI translation is optional. Translation jobs create or update draft variants from the published base snapshot, ensuring that generated translations have a stable source. Generated variants remain drafts and must pass through the normal variant publication service before becoming public.

## Templates, navigation, and static pages

`Template` selects one of the packaged public template families. Public template resolution applies the selected family to layouts and content views; authenticated template previews can temporarily select another family without changing the singleton setting.

Host applications can override packaged public views through normal Rails lookup precedence or copy supported views with `postnhost:views`. Minimal scope copies the default presentation surface; full scope copies every public template, layout, and SEO partial. The engine's packaged CSS remains the default, while the optional host Tailwind generator compiles classes added by copied views.

Navigation can be automatic, derived from published categories and pages, or a custom header/footer tree. Custom internal targets are resolved against public snapshots so links do not expose unpublished content.

Static public pages can come from host or engine ERB templates under `app/views/postnhost/static_pages/`. Database-backed pages share the same public route and snapshot rules. Host templates override engine templates with the same logical path.

## Authentication and authorization

PostnHost uses `has_secure_password` and a session-stored CMS user ID. Onboarding is available only while initial setup is incomplete; after setup, unauthenticated CMS requests redirect to the sign-in page. Signing in and out resets the session.

Authorization is intentionally authentication-only: all signed-in PostnHost users share CMS access. Public draft previews require authentication, while published routes remain anonymous. Hosts that need roles or stronger policy boundaries must extend this contract deliberately.

## Assets and storage

The gem ships precompiled Tailwind CSS, a bundled JavaScript ES module, and namespaced images. The engine initializer registers them with Propshaft or Sprockets, so host applications do not need PostnHost's frontend dependencies merely to render the packaged UI.

CarrierWave handles cover images, inline editor images, avatars, and setting assets. The install generator creates a host-owned CarrierWave initializer because production storage credentials and provider selection belong to the host application.

## Extension and packaging surface

The supported integration surface consists of:

- `Postnhost.configure` defaults and Rails credentials;
- the isolated engine mount path;
- installable migrations;
- public view, static-page, locale, user, and Tailwind generators;
- host view overrides and host locale files;
- the host's Active Job, cache, asset, database, and storage adapters.

The engine must not depend on parent-repository files or host-specific deployment code. The dummy application under `spec/dummy` is compatibility test infrastructure, not a deployment template.

## Architectural invariants

Changes should preserve these rules:

- Anonymous public content reads snapshots, never editable article/page records.
- Localized public content requires both a variant snapshot and its parent snapshot.
- Every publication path uses the shared publishing services.
- A logical publication transaction increments the public-site revision exactly once.
- Publishing captures the PaperTrail version from which the snapshot was written.
- Public route conflicts are rejected at publication time.
- Visitor-visible live configuration changes invalidate through the public revision.
- Storage cleanup preserves files referenced by snapshots and publication history.
- Engine code remains mount-path aware and infrastructure-neutral.
