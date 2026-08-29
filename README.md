<h1 align="center" style="border-bottom: none">
  <div>
    <a href="https://postnhost.com">
      <img alt="PostnHost" src="app/assets/images/postnhost/logo.webp" width="200" />
      <br>
    </a>
  </div>
</h1>
<h3 align="center">
  SEO-ready multilanguage content engine for Rails.
</h3>
<p align="left">
PostnHost is an open source CMS engine built with Rails, Hotwire, and TailwindCSS. Write, translate, and publish articles with a rich text editor, full version history, and proper SEO that works out of the box.
</p>
<p align="left">
Mount this engine into an existing Rails app, or use the <a href="https://github.com/postnhost/postnhost-app">postnhost-app</a> repository for a pre-configured, self-hosted Rails application.
</p>


![PostnHost Demo](app/assets/images/postnhost/demo.webp)

## Features

- 📝 **Rich Text Editor** - TipTap-based WYSIWYG editor
- 🌍 **Multilingual** - Translatable articles, i18n support, and locale-aware SEO metadata
- 🖼️ **Image Management** - Optimized multisize WebP everywhere
- 📊 **Version History** - Published version history and rollback options
- 🤖 **Suggested Articles** - Manual picks plus automatic suggestions from related categories
- ⏰ **Post Scheduling** - Schedule publication in the chosen timezone
- 🌐 **Localized SEO** - Localized routes, language switcher, sitemap, and hreflang tags
- ⚙️ **Settings** - Manage the canonical site URL, pagination, key copy, and assets from the dashboard
- 🎨 **Customizable Templates** - Override any public view in your host application
- ⚡ **Hotwire-powered** - Fast, modern UI with Turbo Frames/Streams and Stimulus
- 👥 **Authors** - Multiple CMS users, author profiles, and per-article co-author bylines

## Table of contents

- [Architecture](ARCHITECTURE.md)
- [Installation](#installation)
- [Asset compatibility](#asset-compatibility)
- [Configuration](#configuration)
- [Customizing templates](#customizing-templates)
  - [Replacing favicon](#replacing-favicon)
  - [Host app i18n](#host-app-i18n-optional)
  - [Static pages](#static-pages-terms-privacy-etc)
- [Routes](#routes)
- [Manual configuration](#manual-configuration)
- [Development](#development)
- [License](#license)

## Installation

### Requirements

- Ruby 3.4+
- Rails 7.2+
- libvips for image processing

Until the gem is published, clone this repository next to your host Rails application and use the local path:

```ruby
gem "postnhost", path: "../postnhost"
```

Run the installer:

```bash
bundle install
bin/rails g postnhost:install
```

This will:
- Create `config/initializers/postnhost.rb` with configuration options
- Create `config/initializers/carrierwave.rb` (if not exists)
- Mount the engine in your routes

Run migrations:

```bash
bin/rails postnhost:install:migrations
bin/rails db:migrate
```

### First-time CMS setup

If there are no users yet, visit **`/blog/onboarding`** to create the first CMS administrator with credentials you choose. This is the default installer path; if you mount the engine somewhere else, open `<mount-path>/onboarding`. The setup flow can add optional sample content after the account is created.

Alternatively, create a CMS user interactively from the terminal:

```bash
bin/rails g postnhost:user
```

The generator prompts for the name, email, password, and password confirmation.

## Asset compatibility

PostnHost ships precompiled CSS and a prebundled JavaScript ES module. The engine serves these files through Rails asset helpers, so the host application does not need to compile PostnHost's JavaScript or install its frontend dependencies.

| Host setup | Compatible | How PostnHost integrates |
| --- | --- | --- |
| Propshaft | ✅ | The engine registers its packaged builds and images with the host asset pipeline. |
| Sprockets | ✅ | The engine registers its packaged builds and images for precompilation. |
| `importmap-rails` | ✅ | The engine bundle is loaded separately from the host import map. No pins are required. |
| `jsbundling-rails` with esbuild | ✅ | The engine uses its packaged bundle and does not need to be added to the host esbuild entry point. |
| `cssbundling-rails` or host Tailwind CSS | ✅ | The packaged engine CSS works independently. Use PostnHost host-tailwind mode only when copied views introduce new Tailwind classes. |

A host application must use Propshaft or Sprockets to serve the packaged engine assets, and either pipeline can be paired with import maps or esbuild.

## Configuration

### Initializer (`Postnhost.configure`)

Edit `config/initializers/postnhost.rb`:

```ruby
Postnhost.configure do |config|
  # Site defaults used when the matching Dashboard → Settings field is blank
  # config.site_url = 'https://example.com'
  # config.public_page_size = 12
  # config.default_timezone = 'UTC'

  # Optional: required only for AI-assisted translations
  # config.openai_api_key = 'sk-...'
  # config.openai_gpt_model = 'gpt-5-mini'

  # Required by the generated CarrierWave initializer in production
  # config.aws_access_key_id = 'AKIA...'
  # config.aws_secret_access_key = '...'
  # config.aws_region = 'us-east-1'
  # config.aws_bucket = 'my-bucket'
  # config.aws_endpoint_url_s3 = 'https://fly.storage.tigris.dev'
end
```

Site URL, pagination, and timezone values are optional defaults; values saved under **Dashboard → Settings** take priority. The OpenAI settings are optional and needed only for AI translations.

The generated CarrierWave initializer uses S3-compatible storage in production. Configure the relevant AWS/S3 values above before deploying; `aws_endpoint_url_s3` is needed only for providers that use a custom endpoint. Alternatively, edit `config/initializers/carrierwave.rb` to use a different production storage backend.

Set dashboard overrides for the canonical site URL and public articles per page under **Dashboard → Settings → Site**. When both site URL sources are blank, public URLs use the incoming request origin.

### Rails credentials (alternative)

Instead of defining values in the initializer, you can add them under `postnhost:` in Rails credentials (`bin/rails credentials:edit`).

```yaml
postnhost:
  # For AI translations
  openai_access_token: ...
  openai_gpt_model: gpt-5-mini

  # For image uploads (S3-compatible)
  aws_access_key_id: AKIA...
  aws_secret_access_key: ...
  aws_region: us-east-1
  aws_bucket_name: my-bucket
  aws_endpoint_url_s3: https://s3.us-east-1.amazonaws.com  # or Tigris/other S3-compatible
```

## Customizing templates

PostnHost includes three public templates: **Default**, **Swiss Editorial**, and **Workspace Journal**. Open **Template** in the CMS, choose a template, preview it, and save the selection.

Copy views to your application for manual/vibecoding customization:

```bash
bin/rails g postnhost:views --views-scope=minimal
# or
bin/rails g postnhost:views --views-scope=full
```

Host-application copies override the packaged engine views. The CMS selection still controls which template is active.

By default, PostnHost serves packaged engine CSS (`postnhost/application.css`) for zero-setup installs.
If your copied views introduce new Tailwind utility classes, enable host-tailwind mode so those classes are compiled in the host app.

`--views-scope=minimal`:
- Copies the Default public content templates under `app/views/postnhost/public/templates/default/`
- Copies shared public layout partials such as the footer, favicon, logo, and language switcher
- Excludes internal metadata partials under `content_for/`
- Keeps SEO/meta internals in the engine by default

`--views-scope=full`:
- Copies all three public content template sets under `app/views/postnhost/public/templates/`
- Copies their layouts under `app/views/layouts/postnhost/public/templates/`
- Copies metadata, structured-data, and SEO partials

### Host Tailwind mode (for custom classes in overridden views)

Enable host-tailwind mode in your host app:

```bash
bin/rails g postnhost:tailwindcss:install
bin/dev
```

This generator creates:

- `postnhost.tailwind.config.js`
- `app/assets/stylesheets/postnhost/host.tailwind.css`
- `Procfile.dev` watcher entry:
  - `postnhost_css: bundle exec rails postnhost:tailwindcss:watch`
- optional `package.json` scripts (if `package.json` exists):
  - `postnhost:tailwindcss`
  - `postnhost:tailwindcss:watch`

When host-tailwind mode files are present, PostnHost layouts automatically include `postnhost/host.css` after `postnhost/application.css`.
You do not need to edit layout tags.

### Robots.txt sitemap URL (required)

Update the host app `public/robots.txt` so it points to the correct PostnHost sitemap URL.

PostnHost generates `sitemap.xml` automatically from live public articles and pages.

If the engine is mounted at `/`:

```txt
Sitemap: https://your-domain.com/sitemap.xml
```

If the engine is mounted at `/blog`:

```txt
Sitemap: https://your-domain.com/blog/sitemap.xml
```

Set the canonical production origin under **Dashboard → Settings → Site** or with `config.site_url` so sitemap URLs are generated with the correct host.

### Replacing favicon

PostnHost renders favicon tags from `app/views/layouts/postnhost/_favicon.html.erb` and points to root-level public paths:

- `/favicon.ico`
- `/icon.svg`
- `/apple-touch-icon.png`
- `/site.webmanifest`

Because these are absolute paths, they are served from the **host app** `public/` directory.
Replace the files in your host app:

```bash
# From host app root
cp /path/to/your/favicon.ico public/favicon.ico
cp /path/to/your/icon.svg public/icon.svg
cp /path/to/your/apple-touch-icon.png public/apple-touch-icon.png
cp /path/to/your/site.webmanifest public/site.webmanifest
```

If you need different markup or paths, run either `postnhost:views` command from the template-customization section, then edit:

- `app/views/layouts/postnhost/_favicon.html.erb`

### Host app i18n (optional)

PostnHost ships with locale files for: `en`, `fr`, `de`, `ja`, `ko`, `pt`, `pl`, `es`, `ru`.

You can use PostnHost without extra i18n setup for a single-locale site. **If you use multiple locales** (localized routes, language switcher, or custom `config/locales/*.yml` files), add this to `config/application.rb`:

```ruby
config.i18n.default_locale = :en
config.i18n.available_locales = %i[en fr de ja ko pt pl es ru]
config.i18n.fallbacks = [:en]
```

**Required:** `config.i18n.fallbacks = [:en]` (or a map that ultimately falls back to a default language).

If you want to add more languages, add the locale code to `available_locales` and add `config/locales/<code>.yml`. To scaffold English strings into your host app:

```bash
bin/rails g postnhost:locale it
```

Then translate the values under `postnhost.public` as needed.

### Static pages (Terms, Privacy, etc.)

You can define static public pages directly in your host app under:

- `app/views/postnhost/static_pages/*.html.erb`

You can generate starter templates:

```bash
bin/rails g postnhost:static_pages terms privacy about
```

Examples:

- `app/views/postnhost/static_pages/terms.html.erb` → `/blog/terms`
- `app/views/postnhost/static_pages/privacy.html.erb` → `/blog/privacy`
- `app/views/postnhost/static_pages/about.html.erb` → `/blog/about`

Link helpers:

```erb
<%= link_to "Terms", postnhost.public_static_page_path(slug: "terms") %>
```

## Routes

The engine mounts at `/blog` by default. You can change this in `config/routes.rb`:

```ruby
mount Postnhost::Engine, at: "/blog"
```

### Available Public Routes

- `GET /` - Blog index
- `GET /:locale` - Blog index (localized)
- `GET /search` - Article search
- `GET /:locale/search` - Article search (localized)
- `GET /authors/:slug` - Author show (when author pages are enabled)
- `GET /:locale/authors/:slug` - Author show (localized, when author pages are enabled)
- `GET /:category_slug` - Category articles
- `GET /:locale/:category_slug` - Category articles (localized)
- `GET /:slug` - Article show or static page
- `GET /:locale/:slug` - Article show or static page (localized)
- `GET /preview/:id` - Article preview
- `GET /sitemap.xml` - XML sitemap
- `GET /sitemap.xsl` - Sitemap stylesheet

## Manual configuration

Some parts must still be configured manually in code:

- Favicons
- Robots.txt
- Error pages 404/500 etc.

## Development

For engine development, use Ruby 4.0.6 and Node.js 24+ as listed in `mise.toml`. Install them with mise, or another version manager, then run:

```bash
cd postnhost
bundle install
yarn install
```

Run both JS and CSS watchers in one command:

```bash
yarn dev
```

### Running tests

From the engine root:

```bash
bundle install
yarn install
bundle exec rake prepare_test_db
bundle exec rspec
```

System specs run with Selenium headless by default. Use visible Chrome when needed:

```bash
SYSTEM_TESTS_BROWSER=1 bundle exec rspec spec/system
```

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
