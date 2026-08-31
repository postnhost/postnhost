CRITICAL: Never use variable assignments in ERB views (for example, `<% description = page_description %>`).

CRITICAL: Do not add speculative fallbacks or undocumented backward-compatibility paths. Preserve documented public APIs and the supported Ruby and Rails compatibility ranges.

# AGENTS.md — PostnHost Engine

This file is the canonical, self-contained guidance for the PostnHost mountable Rails engine. Paths in this document are relative to the engine root.

## Repository Boundary

The engine owns reusable CMS models, controllers, services, generators, views, assets, translations, and engine tests. Host applications own deployment, database operations, backup infrastructure, monitoring mounts, branding overrides, and production credentials.

Never rely on host-application files, parent instructions, or parent-relative runtime paths. The self-hosted application lives in the separate `postnhost-app` repository, and this engine must remain independently buildable and testable.

## Project Overview

PostnHost is a mountable Rails engine with Hotwire, Stimulus, Tailwind CSS, PaperTrail, CarrierWave, and optional OpenAI-backed translation workflows.

- Supported Ruby: 3.4 and 4.0.
- Supported Rails: 7.2, 8.0, and 8.1.
- Namespace: `Postnhost`.
- Authentication: custom session-based authentication with `has_secure_password`.
- Authorization: authenticated CMS/internal flows use `before_action :authenticate_user!`.
- Assets: precompiled Tailwind CSS and a bundled JavaScript ES module ship in the gem.
- Tests: RSpec model, service, concern, helper, request, generator, and Selenium system specs.
- Compatibility: Appraisal gemfiles exercise the supported Rails matrix against the dummy application.

## Working Rules

### Read Before Editing

- Read every relevant file in full before changing it.
- Search for implementations, references, tests, generators, and copied-view manifests before adding code.
- Inspect `git status` and preserve unrelated user changes.
- Consider multiple approaches and prefer the smallest cohesive design.
- Review the final diff and remove code, comments, assets, or compatibility branches that do not serve the requested behavior.

### File Hygiene

- New files must use mode `644` unless intentionally executable.
- Never commit dummy uploads, databases, logs, coverage, temporary output, editor files, or JavaScript source maps.
- Generated distributable CSS and JavaScript under `app/assets/builds/postnhost/` are intentional gem inputs and must be committed after source changes.
- Keep fixtures under `spec/fixtures/`, not under dummy runtime directories.

### Quality Checks

- Run `bundle exec rubocop -a` before finishing Ruby changes.
- Run focused specs while iterating, then the relevant complete engine suite.
- Rebuild packaged JS and CSS when their inputs change.
- Build and inspect the gem when packaging, assets, metadata, generators, or migrations change.

## Architecture

### Models

- Persistent domain rules belong in models: validations, associations, callbacks, scopes, and simple record behavior.
- Keep models focused and extract behavior only when it is genuinely shared.
- Use `touch: true` to represent cache invalidation dependencies.
- Do not wrap Active Record relations with `Array(...)`; handle `nil` explicitly and preserve relation-friendly APIs.

### Services

- Workflow orchestration, external integrations, multi-model commands, and procedural operations belong under `app/services/postnhost/`.
- Inherit application services from `Postnhost::BaseService`.
- Expose `.call(...)` through `BaseService.call`, with one public instance `call` method.
- Return `Postnhost::ServiceResult` when callers need `value`, `errors`, and `status`.
- Keep initializers explicit for required inputs and injected dependencies.
- Do not call `super()` unless a parent initializer actually has state to initialize.
- Split long step-based workflows into descriptive classes under a `steps/` directory.

### Concerns

- Use `ActiveSupport::Concern` for cohesive behavior intentionally mixed into multiple models or controllers.
- Keep one responsibility per concern and namespace it under `Postnhost` where appropriate.
- Do not use concerns as command or workflow buckets.

### Controllers

- Keep controllers under 100 lines and delegate domain behavior to models or services.
- Use strong parameters and explicit `before_action` loaders.
- Protect internal controllers with `before_action :authenticate_user!`.
- Prefer redirects over renders after state changes.
- Prefer standard Rails responses and Turbo Streams over client-managed API flows.

## Views and Generators

### ERB

- Never assign variables in ERB templates.
- Keep templates declarative; prepare data in controllers, models, helpers, or presenters.
- Use `form_with`, `button_to`, Rails helpers, partials, and flash messages. Never add raw `<form>` elements.
- Use semantic HTML and add `cursor-pointer` to clickable controls.
- Public helpers must be limited to data, URLs, sanitization, and formatting; keep public presentation markup and Tailwind classes in templates.

### Public View Copying

- Host applications can copy public templates with `rails g postnhost:views`.
- Whenever a public template under `app/views/postnhost/public/` or public layout partial under `app/views/layouts/postnhost/` is added, moved, or removed, update `lib/generators/postnhost/views/views_generator.rb` and its specs.
- Keep minimal and full view scopes internally consistent.
- Do not ship public UI that the generator cannot copy to a host application.

### Other Generators

- Generators must be safe, deterministic, and covered under `spec/lib/postnhost/generators/`.
- Generated initializers and host files should use current APIs only; do not emit deprecated alternatives or fallbacks.
- Migrations in `db/migrate/` are the source copied into host applications.

## Hotwire and JavaScript

### Server First

- Default to Turbo Drive, Frames, Streams, Rails forms, and `button_to`.
- Use Stimulus only for interactions that need browser-local state or behavior.
- Avoid JavaScript `fetch` for submissions Rails forms can handle.
- Links to mutable actions must use `data: { turbo_prefetch: false }`.

### Stimulus Controllers

- Controllers live in `app/javascript/controllers/` and must be registered in `app/javascript/controllers/index.js`.
- Keep controllers focused and under 100 lines when practical.
- Use camelCase targets and typed values.
- Use `#privateMethod` syntax for internal methods.
- Use arrow functions for event callbacks that need lexical `this`.
- Clean up listeners, timers, observers, and other resources in `disconnect()`.
- Use controller targets instead of global DOM IDs.
- Put shared DOM and style behavior in the existing helpers rather than duplicating class mutations.

## Tailwind, Icons, and Packaged Assets

- Use Tailwind utility classes only; do not add custom CSS files or inline styles.
- Source CSS lives under `app/assets/stylesheets/`.
- Packaged outputs are:
  - `app/assets/builds/postnhost/application.css`
  - `app/assets/builds/postnhost/application.js`
- CSS selectors are build-time scoped under `html[data-postnhost]`; every shipped PostnHost layout must keep the `data-postnhost` root attribute.
- Host Tailwind mode compiles the engine and copied host views into a host-owned `postnhost/application.css` that shadows the packaged logical asset, so engine runtime code never depends on a host stylesheet name.
- Do not generate or ship source maps.
- Rebuild both outputs before committing changes to their inputs.
- The gem must work without requiring frontend dependencies in the host application.
- Icons live under `app/assets/images/postnhost/icons/`.
- Use Heroicons outline SVGs with `stroke-width="1.5"`, remove `class="size-6"`, and render them through the `icon` helper.

## Publishing, Caching, and Internationalization

### Publishing and Snapshots

- Draft records remain editable; public reads use published snapshots.
- Manual, scheduled, bulk, and restore-and-publish flows must share the same transactional publishing services.
- PaperTrail records draft history and does not replace snapshot publication semantics.
- Preserve uploaded files referenced by snapshots or historical versions.

### Caching

- Prefer HTTP conditional requests and fragment caching at reusable partial boundaries.
- Let timestamps and touch cascades invalidate cache keys.
- Do not manually expire caches when model timestamps represent the dependency.
- Never cache user-specific CMS data in shared fragments.
- Public writes must increment the public-site revision through the established publication workflow.

### Internationalization

- Public UI strings live under `config/locales/` in the `postnhost.public` namespace.
- English is the source locale and fallback target configured by the host.
- Runtime overrides come from `Postnhost::Setting#locale_overrides`; blank values remove an override.
- The settings editor must expose only locales backed by `Postnhost::Language` records.
- Site SEO metadata comes from `postnhost.public.site.*` keys or explicit settings, not hardcoded helper constants.
- Add every required key to every shipped locale or deliberately rely on the host’s English fallback.

## Testing

### Commands

```bash
# Prepare the dummy application database
bundle exec rake prepare_test_db

# Complete engine suite
bundle exec rspec

# Non-system specs
bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"

# System specs
bundle exec rspec spec/system

# Visible browser
SYSTEM_TESTS_BROWSER=1 bundle exec rspec spec/system

# Rails compatibility example
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle exec rake prepare_test_db
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle exec rspec
```

### Conventions

- Request specs hardcode default language, authentication, and host setup in each file; do not introduce shared defaults for these.
- Define `let!(:default_language) { create(:language, :default) }` explicitly where required.
- Define `let(:user) { create(:user) }` and `before { sign_in user }` explicitly for authenticated request specs.
- Use `before { host! "example.com" }` explicitly for host-dependent request specs.
- Prefer `have_http_status(:ok)` for successful responses and strict boolean matchers where exact values matter.
- Keep route descriptions aligned with the actual HTTP verb and path.
- Test behavior rather than private methods or instance variables.
- Stub external HTTP requests with WebMock.
- System specs use Selenium; do not use Rack::Test APIs or direct model mutations in place of UI flows.

## Packaging and Compatibility

- `postnhost.gemspec` is the public package contract.
- Keep its Ruby and Rails requirements aligned with `README.md`, `Appraisals`, and CI.
- Package runtime code, migrations, locales, generators, public assets, `LICENSE`, and `README.md`.
- Exclude specs, the dummy app, logs, databases, uploads, source maps, and local tooling artifacts.
- Keep `Gemfile.lock`, `yarn.lock`, appraisal gemfiles, and appraisal lockfiles for reproducible development and CI.
- The dummy app is test infrastructure, not a deployable product.
- Verify Propshaft and Sprockets compatibility when changing asset registration or paths.

## Key Engine Files

- `postnhost.gemspec` — package metadata, compatibility, and file manifest.
- `lib/postnhost/engine.rb` — engine integration and asset registration.
- `lib/generators/postnhost/` — host installation and customization generators.
- `app/services/postnhost/base_service.rb` and `app/services/postnhost/service_result.rb` — service conventions.
- `app/services/postnhost/publishing/` — public snapshot workflows.
- `app/views/postnhost/public/` and `app/views/layouts/postnhost/` — copyable public UI.
- `app/javascript/controllers/index.js` — Stimulus registration.
- `db/migrate/` — installable schema changes.
- `spec/dummy/` — compatibility test host.
- `gemfiles/` and `Appraisals` — Rails support matrix.

Prefer cohesive Rails code, explicit contracts, and a small host integration surface.
