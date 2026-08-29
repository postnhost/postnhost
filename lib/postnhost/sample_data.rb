module Postnhost
  module SampleData
    DEFAULT_COVER_IMAGE_ALT = "PostnHost"
    DEFAULT_COVER_IMAGE_PATH = "app/assets/images/og-image.webp"

    module_function

    def seed!(user:)
      raise ArgumentError, "user is required" unless user.is_a?(Postnhost::User)

      seed_author_profile!(user)
      seed_categories!
      seed_articles!(user)
    end

    def seed_author_profile!(user)
      attributes = sample_author_profile.filter { |field, _value| user.public_send(field).blank? }
      return if attributes.blank?

      user.update!(attributes)
    end

    def seed_categories!
      categories_data.each do |cat_data|
        Postnhost::Category.find_or_create_by!(name: cat_data[:name]) do |cat|
          cat.slug = cat_data[:slug]
          cat.meta_description = cat_data[:meta_description]
        end
      end
    end

    def seed_articles!(user)
      default_language = Postnhost::Language.blog_default
      raise "Set a default language before seeding articles" if default_language.blank?

      categories = Postnhost::Category.where(name: categories_data.pluck(:name)).index_by(&:name)

      demo_articles_data.each_with_index do |article_data, _index|
        article = Postnhost::Article.find_or_create_by!(title: article_data[:title]) do |art|
          art.content = article_data[:content]
          art.user = user
          art.language = default_language
          art.meta_description = article_data[:meta_description]
        end

        selected_categories = article_data.fetch(:category_names).map { |name| categories.fetch(name) }
        article.categories = selected_categories unless article.category_ids == selected_categories.map(&:id)

        source = resolve_cover_image_source(article_data.fetch(:cover_image_path, DEFAULT_COVER_IMAGE_PATH))
        if source && !article.cover_image?
          File.open(source, "rb") do |file|
            article.cover_image = file
            article.cover_image_alt = article_data.fetch(:cover_image_alt, DEFAULT_COVER_IMAGE_ALT)
            article.save!
          end
        end

        next if article.published? && !article.unpublished_changes?

        result = Postnhost::Publishing::Articles::Publish.call(article:)
        raise result.errors.to_sentence unless result.success?
      end
    end

    def sample_author_profile
      {
        position: "Editor",
        bio: "Demo author for PostnHost, writing about Rails, publishing workflows, and durable content systems. This seeded profile shows how public author pages render a biography and social links.",
        website_url: "https://example.com/demo-author",
        x_url: "https://x.com/postnhostdemo",
        linkedin_url: "https://linkedin.com/in/postnhost-demo",
        youtube_url: "https://youtube.com/@postnhostdemo",
        bluesky_url: "https://bsky.app/profile/postnhost-demo.example.com"
      }
    end

    def categories_data
      [
        {
          name: "Getting Started",
          slug: "getting-started",
          meta_description: "Start here for an introduction to PostnHost and its core publishing features."
        },
        {
          name: "Site Setup",
          slug: "site-setup",
          meta_description: "Configure your PostnHost site navigation, branding, assets, and public experience."
        },
        {
          name: "Publishing",
          slug: "publishing",
          meta_description: "Manage authors, article discovery, publishing schedules, and version history in PostnHost."
        },
        {
          name: "Localization",
          slug: "localization",
          meta_description: "Add languages, customize public text, and publish translated content with PostnHost."
        },
        {
          name: "SEO",
          slug: "seo",
          meta_description: "Configure PostnHost structured data, author schema, and sitemap SEO."
        }
      ]
    end

    def demo_articles_data
      [
        {
          title: "Navigation Links in PostnHost",
          content: navigation_links_article_html,
          meta_description: "Learn how to build PostnHost header links, dropdowns, footer columns, localized labels, external links, and text-only navigation items.",
          category_names: ["Site Setup"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/16-navigation-links.webp",
          cover_image_alt: "PostnHost navigation"
        },
        {
          title: "How to Add and Manage Languages",
          content: languages_article_html,
          meta_description: "Learn how to add languages in PostnHost, choose a default language, understand content counts, and prepare an optional custom locale.",
          category_names: ["Localization"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/13-languages.webp",
          cover_image_alt: "PostnHost languages"
        },
        {
          title: "How to Customize Public Text for Each Language",
          content: public_text_article_html,
          meta_description: "Learn how to customize your PostnHost site name, tagline, subtitle, and social text for each language.",
          category_names: ["Localization"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/19-public-text-for-each-language.webp",
          cover_image_alt: "Localized public text"
        },
        {
          title: "Configure Structured Data (Schema) and Sitemap SEO",
          content: schema_and_sitemap_article_html,
          meta_description: "A simple guide to setting up site schema, article defaults, author details, and the PostnHost sitemap.",
          category_names: ["SEO"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/20-structured-data-and-sitemap-seo.webp",
          cover_image_alt: "Schema and sitemap SEO"
        },
        {
          title: "How to Control Suggested Articles and Top Picks",
          content: suggested_articles_and_top_picks_article_html,
          meta_description: "Learn how to choose suggested articles, use automatic suggestions, and feature articles in the PostnHost Top Picks block.",
          category_names: ["Publishing"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/08-suggested-articles-and-top-picks.webp",
          cover_image_alt: "Suggested articles and Top Picks"
        },
        {
          title: "How to Schedule an Article for Publication",
          content: scheduling_article_html,
          meta_description: "Learn how to set a site timezone, schedule a PostnHost article, update or cancel its schedule, and check publication status.",
          category_names: ["Publishing"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/11-scheduling.webp",
          cover_image_alt: "Article scheduling"
        },
        {
          title: "All About Authors in PostnHost",
          content: authors_article_html,
          meta_description: "Learn how to create author profiles, assign multiple authors, manage public author pages, and understand author removal in PostnHost.",
          category_names: ["Publishing"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/09-authors.webp",
          cover_image_alt: "PostnHost authors"
        },
        {
          title: "How Article Version History and Restores Work",
          content: version_history_article_html,
          meta_description: "Learn how PostnHost saves published article versions, previews older versions, and restores a version safely to the draft.",
          category_names: ["Publishing"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/12-version-history.webp",
          cover_image_alt: "Article version history"
        },
        {
          title: "How to Add a Logo and Default OG Image",
          content: brand_assets_article_html,
          meta_description: "Learn how to add your site logo and default social sharing image in PostnHost.",
          category_names: ["Site Setup"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/17-logo-and-default-og-image.webp",
          cover_image_alt: "Logo and default OG image"
        },
        {
          title: "How to Translate Articles, Pages, and Categories",
          content: translations_article_html,
          meta_description: "Learn how to create, review, publish, and manage manual or AI-assisted translations in PostnHost.",
          category_names: ["Localization"],
          cover_image_path: "app/assets/images/postnhost/sample-docs/covers/14-translations.webp",
          cover_image_alt: "Content translations"
        },
        {
          title: "Welcome to PostnHost",
          content: welcome_article_html,
          meta_description: "PostnHost: open source Rails CMS with TipTap, multilingual SEO, Solid Queue and Solid Cache, single SQLite database, Litestream backups, and Hotwire UI. Self-hosted app or mountable engine—MIT licensed.",
          category_names: ["Getting Started"],
          cover_image_path: DEFAULT_COVER_IMAGE_PATH,
          cover_image_alt: DEFAULT_COVER_IMAGE_ALT
        }
      ]
    end

    def navigation_links_article_html
      <<~HTML
        <h2>Build navigation around your content</h2>
        <p>PostnHost can create public navigation automatically from your categories and pages, or you can replace it with a custom structure. Custom navigation is useful when you want a smaller header, a grouped dropdown, dedicated footer columns, an external newsletter link, or different labels for each language.</p>
        <p>This guide shows how to switch to custom navigation, add header and footer items, choose the right target type, localize labels, and verify the result. You will work in <strong>Settings → Navigation</strong>.</p>

        <h2>Before you start</h2>
        <p>Create and publish the content you want to link before building the menu. The Article and Page target lists contain published content. A category link also needs published content in that category before it can resolve on the public site. If your site uses multiple languages, create the Language records and publish the relevant translations first.</p>
        <p>Keep a second browser tab open on the public site so you can check the desktop header, mobile menu, and footer after saving.</p>

        <h2>Switch from automatic to custom navigation</h2>
        <ol>
          <li>Sign in to PostnHost and open <strong>Settings</strong>.</li>
          <li>Select <strong>Navigation</strong> from the settings menu.</li>
          <li>Choose the language whose labels you want to edit.</li>
          <li>Turn off <strong>Use auto-generated navigation</strong>.</li>
        </ol>
        <p>The custom builder now shows two areas: <strong>Header Navigation</strong> and <strong>Footer Columns</strong>. Turning off automatic navigation does not copy the generated menu into the builder. You are creating a new, intentional structure.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/16-how-to-add-navigation-links-01-navigation-builder.webp')}" alt="PostnHost custom navigation builder with a header link, a dropdown containing child links, and a footer column.">
        </div>
        <p><em>Custom navigation can combine direct header links, grouped dropdowns, and footer columns in one localized structure.</em></p>

        <h2>Add a link to the header</h2>
        <ol>
          <li>Under <strong>Header Navigation</strong>, select <strong>Link</strong>.</li>
          <li>Enter a label for the selected language. The label is optional for most internal targets because PostnHost can use the target title.</li>
          <li>Choose a <strong>Target Type</strong>.</li>
          <li>Choose the target or enter the external URL.</li>
        </ol>
        <p>Use a custom label when the content title is too long for navigation. For example, a page titled “About the Fieldnotes Editorial Team” could use the shorter label “About.”</p>

        <h3>Choose the right target type</h3>
        <ul>
          <li><strong>Article</strong> links to a published article.</li>
          <li><strong>Page</strong> links to a published CMS page.</li>
          <li><strong>Category</strong> links to the public listing for that category.</li>
          <li><strong>Static Page</strong> links to a code-defined page such as Terms or Privacy.</li>
          <li><strong>External Link</strong> opens a complete URL outside the site in a new tab.</li>
          <li><strong>Text</strong> displays a label without creating a link.</li>
        </ul>
        <p>Text items work well as small section labels, but they do not have a destination. Use them sparingly so visitors do not mistake them for broken links.</p>

        <h2>Create a header dropdown</h2>
        <p>A dropdown groups related destinations without crowding the main header. Under <strong>Header Navigation</strong>, select <strong>Dropdown</strong>, give the group a clear label, and use <strong>+ Add link</strong> to add its children.</p>
        <p>Each child uses the same target choices as a standalone header link. A useful structure might be a “Learn” dropdown containing a guide article, an About page, and a Guides category. Keep the list short enough to scan quickly on both desktop and mobile.</p>

        <h2>Build footer columns</h2>
        <p>Under <strong>Footer Columns</strong>, select <strong>Column</strong>. Give the column a label such as “Company,” “Resources,” or “Legal,” then add its child links. Footer columns can combine internal pages, static pages, external links, and text items.</p>
        <p>A practical footer could contain a Company column with About and Contact pages, plus a Legal column with Terms and Privacy static pages. Custom footer links replace the built-in category and page groups used by automatic navigation.</p>

        <h2>Add an external link safely</h2>
        <p>Choose <strong>External Link</strong> and enter the full address, including <code>https://</code>. PostnHost opens external navigation links in a new tab and adds protective relationship attributes automatically.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/16-how-to-add-navigation-links-02-external-link-settings.webp')}" alt="PostnHost navigation link configured as an External Link with a complete URL and the Add nofollow option.">
        </div>
        <p><em>External links require a complete URL; use Add nofollow only when the destination should not receive an editorial endorsement.</em></p>
        <p>Enable <strong>Add nofollow</strong> when you do not want search engines to treat the link as an editorial endorsement. This can be appropriate for paid, sponsored, or otherwise untrusted destinations. It is usually unnecessary for your organization’s own newsletter, store, or social profile.</p>

        <h2>Reorder and remove items</h2>
        <p>Use the drag handle to reorder items within the same header, dropdown, or footer-column list. Items cannot be dragged from one container into another. To move a destination between containers, remove it from the old location and add it to the new one.</p>
        <p>Use the remove control on an item when it is no longer needed. Nothing changes on the public site until you select <strong>Save Navigation</strong>.</p>

        <h2>Localize navigation labels</h2>
        <p>Use the <strong>Language</strong> selector at the top of Navigation settings to edit labels for another locale. The underlying destination stays the same while the visible label can change. If a localized label is blank, PostnHost falls back to the default-language label and then to the target’s title when available.</p>
        <p>Internal links are locale-aware. When a translated article or page is published, visitors in that language are sent to the localized version. If a translated article or page is unavailable, PostnHost can use the default-language destination. Category links require published content for the active language, so verify them in every locale you support.</p>

        <h2>Save and verify the result</h2>
        <ol>
          <li>Select <strong>Save Navigation</strong>.</li>
          <li>Open the public site in the default language and test every header link.</li>
          <li>Open each dropdown and confirm its children appear in the intended order.</li>
          <li>Reduce the browser width and test the mobile navigation.</li>
          <li>Scroll to the footer and test each column and external link.</li>
          <li>Repeat the check for every supported language.</li>
        </ol>
        <p>If an internal target is missing from a selector, publish the article or page and return to Navigation settings. If a category link does not appear publicly, confirm that the category contains a published article for the language you are testing.</p>
      HTML
    end

    def brand_assets_article_html
      <<~HTML
        <h2>Give your public site its own identity</h2>
        <p>PostnHost uses two main brand images across the public site: a <strong>Site Logo</strong> and a <strong>Default OG Image</strong>. The logo identifies your publication in the header and other shared areas. The default OG image is used when a page is shared on social networks and does not have a more specific image of its own.</p>
        <p>You can manage both from <strong>Settings → Assets</strong>.</p>

        <h2>Prepare the two images</h2>
        <p>Use a clean logo that remains readable at a small size. A transparent PNG or WebP usually works well. For the default sharing image, prepare a horizontal image with your publication name or a simple brand treatment. A size of <strong>1200 × 630 pixels</strong> is a reliable choice for social previews.</p>
        <p>PostnHost accepts PNG, JPEG, GIF, WebP, and HEIC images. Keep the files reasonably small so public pages stay quick to load.</p>

        <h2>Add the Site Logo</h2>
        <ol>
          <li>Open <strong>Settings</strong> and select <strong>Assets</strong>.</li>
          <li>Under <strong>Site Logo</strong>, choose the logo file from your computer.</li>
          <li>Wait for the preview to update.</li>
          <li>Select <strong>Save Assets</strong> if the page still shows unsaved changes.</li>
        </ol>
        <p>The preview lets you check whether the logo is clear at the size used by the site. If it looks crowded or too small, simplify the source image and upload it again.</p>

        <h2>Add the Default OG Image</h2>
        <ol>
          <li>Find <strong>Default OG Image</strong> on the same page.</li>
          <li>Choose the horizontal sharing image.</li>
          <li>Check the large preview for unexpected cropping or unreadable text.</li>
          <li>Select <strong>Save Assets</strong> when needed.</li>
        </ol>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/17-how-to-add-a-logo-and-default-og-image-01-assets-settings.webp')}" alt="PostnHost Assets settings showing the Site Logo and Default OG Image previews and their upload controls.">
        </div>
        <p><em>Settings → Assets keeps the publication logo and default social image together.</em></p>

        <h2>Know when the default image appears</h2>
        <p>The Default OG Image is a site-wide fallback. An article with its own cover image uses that article image when it is shared. Pages without a specific image can use the default instead. This lets you keep a consistent brand while still giving important stories their own visual.</p>

        <h2>Replace or remove an image</h2>
        <p>To replace an asset, choose a new file in the same field and save. To remove an uploaded image, use the trash control beside its preview and confirm the action. PostnHost then returns to its packaged default where one is available.</p>

        <h2>Check the result</h2>
        <p>Open the public site in another tab and confirm that the logo is sharp and correctly sized. Then view a page without its own cover image and use your preferred social-preview tool to check the sharing image. If either asset includes text, test it on both a large screen and a phone-sized preview.</p>

        <h2>Configure S3-compatible storage</h2>
        <p>PostnHost stores uploads on the local filesystem in development. In production, configure an S3 bucket or an S3-compatible service such as Tigris so uploaded logos, social images, cover images, and editor images remain available after a deployment.</p>
        <p>Open the encrypted credentials editor:</p>
        <pre><code class="language-bash">bin/rails credentials:edit</code></pre>
        <p>Add the upload credentials under <code>postnhost:</code>:</p>
        <pre><code class="language-yaml">postnhost:
          aws_access_key_id: YOUR_ACCESS_KEY
          aws_secret_access_key: YOUR_SECRET_KEY
          aws_region: us-east-1
          aws_bucket_name: your-upload-bucket
          aws_endpoint_url_s3: https://s3.us-east-1.amazonaws.com</code></pre>
        <p>Use the endpoint supplied by your storage provider. Keep these values out of source control, confirm that <code>config/initializers/carrierwave.rb</code> exists, and make sure uploaded objects can be served publicly. Restart the production app after changing credentials, upload a small test image under <strong>Settings → Assets</strong>, and confirm that it still loads from its public URL.</p>
        <p>You can instead set the matching values in <code>config/initializers/postnhost.rb</code>. In that initializer the bucket option is named <code>config.aws_bucket</code>; explicit initializer values take priority over encrypted credentials.</p>
      HTML
    end

    def public_text_article_html
      <<~HTML
        <h2>Make the public site sound right in every language</h2>
        <p>PostnHost lets you change shared public text without editing an article or page. This includes the site name, tagline, subtitle, meta title, and meta description shown for a particular language.</p>
        <p>These settings change the words around your content. They do not translate article, page, or category content.</p>

        <h2>Choose the language</h2>
        <ol>
          <li>Open <strong>Settings</strong> and select <strong>I18n</strong>.</li>
          <li>Use the <strong>Locale</strong> menu to choose the language you want to edit.</li>
          <li>Review the existing values before making changes.</li>
        </ol>
        <p>Only languages already available on your site appear in this menu. If the language is missing, add it from <strong>Languages</strong> first.</p>

        <h2>Edit the main public text</h2>
        <p>The first fields cover the text most site owners need:</p>
        <ul>
          <li><strong>Site Name</strong> is the publication name used across the public site and in site information.</li>
          <li><strong>Tagline</strong> is the short label near the main blog heading.</li>
          <li><strong>Subtitle</strong> introduces the publication or its latest content.</li>
          <li><strong>Meta Title</strong> is the default title used for the blog index in search and browser tabs.</li>
          <li><strong>Meta Description</strong> summarizes the publication for search and sharing previews.</li>
        </ul>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/19-how-to-customize-public-text-for-each-language-01-i18n-overrides.webp')}" alt="PostnHost I18n settings with Spanish selected and the main public site text fields visible.">
        </div>
        <p><em>Select a locale first, then edit only the public text for that language.</em></p>

        <h2>Save and review the public page</h2>
        <ol>
          <li>Update the fields you want to change.</li>
          <li>Select <strong>Save I18n</strong>.</li>
          <li>Open the public site in that language.</li>
          <li>Check the page heading, subtitle, browser title, and sharing description.</li>
        </ol>
        <p>Keep titles concise and make descriptions useful on their own. A visitor may see this text in search results before seeing the rest of your site.</p>

        <h2>Restore the standard wording</h2>
        <p>If you no longer want a custom value, clear that field and save again. PostnHost returns to the wording supplied by the selected language.</p>

        <h2>Use Advanced only when you need it</h2>
        <p>The <strong>Advanced</strong> section contains smaller interface messages such as navigation labels and empty states. Most sites can leave these values unchanged. If you edit them, change one clear label at a time and check the corresponding public page afterward.</p>

        <h2>Repeat for each language</h2>
        <p>Switch the Locale menu and repeat the same short review for every language you publish. This keeps the site name and introduction consistent while still letting each language read naturally.</p>

        <h2>Optional developer setup: add a language PostnHost does not include</h2>
        <p>You can skip this section when the language you need is already available. If you want to publish in another language, add both a CMS Language record and a matching Rails locale file. For example, to add Italian:</p>
        <ol>
          <li>Open <strong>Languages</strong>, create <strong>Italian</strong>, and use <code>it</code> as the <strong>Language Code</strong>.</li>
          <li>From the host application root, generate a starter locale file:</li>
        </ol>
        <pre><code class="language-bash">bin/rails g postnhost:locale it</code></pre>
        <p>This creates <code>config/locales/it.yml</code> from the English public strings. Translate the values under <code>postnhost.public</code>, while keeping the YAML keys unchanged.</p>
        <p>Add the same locale code to <code>config.i18n.available_locales</code> in <code>config/application.rb</code> and keep English as the fallback:</p>
        <pre><code class="language-ruby">config.i18n.default_locale = :en
        config.i18n.available_locales = %i[en fr de es it]
        config.i18n.fallbacks = [:en]</code></pre>
        <p>The Language Code, filename, YAML root key, and available locale must agree. Restart the application after changing <code>config/application.rb</code>. Then return to the Italian Language page; the missing-locale-file warning should be gone.</p>
      HTML
    end

    def schema_and_sitemap_article_html
      <<~HTML
        <h2>Help search engines understand your publication</h2>
        <p>PostnHost creates structured information about your site, organization, articles, and authors. This information is not a visible design element. It gives search engines a clearer description of who publishes the content and what each page represents.</p>
        <p>You only need to provide a few accurate details. Leave optional fields empty when they do not apply.</p>

        <h2>Start with the public site address</h2>
        <p>Open <strong>Settings → Site</strong> and confirm that the Site URL matches the address visitors use in production. PostnHost uses this address when it creates public links, structured information, and sitemap entries.</p>

        <h2>Add the WebSite details</h2>
        <ol>
          <li>Open <strong>Settings</strong> and select <strong>Schema</strong>.</li>
          <li>Choose the language you want to edit.</li>
          <li>Under <strong>WebSite</strong>, enter the publication name.</li>
          <li>Add a short description of the publication.</li>
        </ol>
        <p>Use the name readers recognize. The description should explain the publication plainly rather than listing keywords.</p>

        <h2>Describe the organization</h2>
        <p>Under <strong>Organization</strong>, choose the option that most closely matches the publisher and enter its public name and description. Add an alternate name, contact details, address, or social profile links only when that information is real and useful.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/20-how-to-configure-structured-data-and-sitemap-seo-01-site-schema.webp')}" alt="PostnHost Schema settings showing WebSite and Organization details for the Fieldnotes publication.">
        </div>
        <p><em>Start with the WebSite name and description, then add only the Organization details that apply.</em></p>
        <p>The organization logo comes from <strong>Settings → Assets → Site Logo</strong>. Update it there if the logo shown in Schema is not the one you want.</p>

        <h2>Choose the default article type</h2>
        <p>In <strong>Article Defaults</strong>, keep <strong>BlogPosting</strong> for most blogs and editorial publications. Choose a more specific option only when it consistently describes your content. Individual articles can use a different type when needed.</p>

        <h2>Add Author Schema</h2>
        <p>Every published article includes information about its assigned authors. PostnHost starts with the author’s regular profile, so complete the name, position, biography, author image, and social links before adding anything extra.</p>
        <ol>
          <li>Open <strong>Authors</strong> and select the author you want to update.</li>
          <li>Choose <strong>Edit Schema</strong>.</li>
          <li>Review <strong>Derived Defaults</strong>. These show the name, job title, description, public URL, and identifier PostnHost can use automatically.</li>
          <li>Select a language under <strong>Schema Overrides</strong> when the author’s name, role, or biography should be different in that language.</li>
          <li>Add optional expertise, awards, or education details only when they are accurate and useful.</li>
          <li>Select <strong>Save Author Schema</strong>.</li>
        </ol>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/20-how-to-configure-structured-data-and-sitemap-seo-02-author-schema-defaults.webp')}" alt="PostnHost Author Schema page for Kirill Shevchenko showing Derived Defaults and generated schema fields.">
        </div>
        <p><em>Derived Defaults show which author details PostnHost can use without extra overrides.</em></p>
        <p>Social links from the author profile are included automatically. Use <strong>sameAs</strong> only for an additional authoritative profile, and leave the optional image field empty when the normal Author Image is already correct.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/20-how-to-configure-structured-data-and-sitemap-seo-03-author-schema-advanced-fields.webp')}" alt="PostnHost Author Schema Global Advanced Fields and Save Author Schema button for Kirill Shevchenko.">
        </div>
        <p><em>Use Global Advanced Fields only for useful details that are not already present in the author profile.</em></p>
        <p>If you want the author’s public profile URL included, open <strong>Settings → Feature Flags</strong> and enable <strong>Author pages</strong>. This also makes public author pages and byline links available.</p>

        <h2>Save and check your sitemap</h2>
        <p>Select <strong>Save Schema</strong>, then open <code>/sitemap.xml</code> on your public site. The sitemap lists published public pages and their language versions so search engines can discover them.</p>
        <p>After publishing or translating content, revisit the sitemap and confirm that the new public URL appears. If your site is mounted below another path, ask the person managing the deployment to confirm that search engines are directed to the correct sitemap address.</p>

        <h2>A simple final check</h2>
        <ul>
          <li>The Site URL uses the real public domain.</li>
          <li>The WebSite and Organization names match the publication.</li>
          <li>The description is short, accurate, and readable.</li>
          <li>The Site Logo is current.</li>
          <li>The default article type fits most of your content.</li>
          <li>Each author has a complete profile and any useful schema additions.</li>
          <li>The sitemap opens and contains published pages.</li>
        </ul>
        <p>That is enough for a strong starting point. Add more details only when they describe something real that readers can verify.</p>
      HTML
    end

    def suggested_articles_and_top_picks_article_html
      <<~HTML
        <h2>Help readers find the next useful article</h2>
        <p>PostnHost offers two separate ways to surface important content. <strong>Suggested Articles</strong> appear as related reading around an article, while <strong>Top Picks Block</strong> marks an article for a featured public block supported by your active template.</p>
        <p>Use suggestions to continue the reader’s current topic. Use Top Picks for a small collection of especially useful or timely articles.</p>

        <h2>Choose suggested articles manually</h2>
        <ol>
          <li>Open the article you want to edit.</li>
          <li>In the <strong>Details</strong> sidebar, expand <strong>Suggested Articles</strong>.</li>
          <li>Select <strong>+ Add suggestion</strong>.</li>
          <li>Choose a relevant article from the selector.</li>
          <li>Repeat when a second suggestion genuinely helps the reader.</li>
          <li>Wait until the editor shows <strong>Saved</strong>.</li>
        </ol>
        <p>Choose published articles that directly extend the current subject. For example, a guide to editorial planning could suggest articles about product updates and maintaining a publishing calendar.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/08-how-to-control-suggested-articles-and-top-picks-01-discovery-controls.webp')}" alt="PostnHost Suggested Articles manager with two selected articles and the Top Picks Block setting enabled.">
        </div>
        <p><em>Manual suggestions and the Top Picks setting are managed independently in the Details sidebar.</em></p>

        <h2>Let PostnHost choose when the list is empty</h2>
        <p>If you do not specify any suggestions, PostnHost automatically selects <strong>three</strong>. This gives a new article a useful related-reading area without requiring manual setup.</p>
        <p>Manual choices are better when the reading path matters. Leave the list empty when the automatic set is good enough, and review the public article after publishing to make sure the suggestions are useful.</p>

        <h2>Remove or replace a suggestion</h2>
        <p>Select the remove control beside an article to take it out of the manual list. You can then add another article, or remove every manual choice to return to the automatic three-article behavior. Wait for <strong>Saved</strong> before leaving the editor.</p>

        <h2>Add an article to Top Picks</h2>
        <ol>
          <li>Expand <strong>Top Picks Block</strong> in the Details sidebar.</li>
          <li>Enable <strong>Show this article in the public Top Picks block</strong>.</li>
          <li>Wait for the change to save, then review the public site.</li>
        </ol>
        <p>Top Picks is a featured-content flag, not a new article sort order. Its exact placement and appearance depend on the public template. If the active template does not display a Top Picks block, enabling the checkbox does not change the normal article list.</p>
      HTML
    end

    def authors_article_html
      <<~HTML
        <h2>Understand what an author represents</h2>
        <p>In PostnHost, an author is both a CMS account and a reusable public profile. The account email and password allow the person to sign in. The public profile supplies the name, role, biography, image, social links, and slug used for article attribution and optional author pages.</p>
        <p>Keeping these two responsibilities clear makes it easier to add teammates without exposing account details on the public site.</p>

        <h2>Create an author account</h2>
        <ol>
          <li>Open <strong>Authors</strong> from the CMS navigation.</li>
          <li>Select <strong>New Author</strong>.</li>
          <li>Enter the author’s name and sign-in email.</li>
          <li>Create a password of at least six characters and confirm it.</li>
          <li>Select <strong>Create Author</strong>.</li>
        </ol>
        <p>Use an email address controlled by the author. Never place a real password in documentation or shared notes. When editing an existing author later, leave both password fields blank to keep the current password.</p>

        <h2>Complete the public profile</h2>
        <p>Open the author from <strong>Authors</strong> and add the information readers should see:</p>
        <ul>
          <li><strong>Author Image</strong> gives the profile and byline a recognizable visual.</li>
          <li><strong>Author Name</strong> is the public display name.</li>
          <li><strong>Position</strong> describes the author’s role. If it is blank, PostnHost uses “Author.”</li>
          <li><strong>Slug</strong> controls the author-page path and is generated from the name when first created.</li>
          <li><strong>BIO</strong> is the short biography shown on the public profile.</li>
          <li><strong>Social Links</strong> should include only profiles the author wants to share publicly.</li>
        </ul>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/09-all-about-authors-in-postnhost-01-author-profile.webp')}" alt="PostnHost Edit Author screen showing Kirill Shevchenko's profile details and expanded Social Links.">
        </div>
        <p><em>The Edit Author screen keeps public profile information separate from sign-in credentials.</em></p>
        <p>Select <strong>Update</strong> after reviewing the profile. Open the public author page when it is enabled and check the biography, links, and image as a reader would see them.</p>

        <h2>Assign authors to an article</h2>
        <p>The person who creates an article is assigned as its first author automatically. To add a co-author:</p>
        <ol>
          <li>Open the article editor.</li>
          <li>Expand <strong>Authors</strong> in the Details sidebar.</li>
          <li>Select <strong>+ Add author</strong>.</li>
          <li>Choose the author from the selector and wait for <strong>Saved</strong>.</li>
        </ol>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/09-all-about-authors-in-postnhost-02-multiple-authors.webp')}" alt="PostnHost article Authors manager showing Kirill Shevchenko and Sam Rivera with the add-author selector open.">
        </div>
        <p><em>An article can retain multiple authors in their assignment order.</em></p>
        <p>Use the remove control beside a name when that person should no longer be attributed. Author order is preserved, and templates that show only one author use the first assigned author. Add the primary contributor first, then supporting contributors in the order you want retained.</p>

        <h2>Control public author pages</h2>
        <p>Open <strong>Settings → Feature Flags</strong> and enable <strong>Author pages</strong> when readers should be able to open public author profiles from bylines. Disabling the feature removes public author-profile routes and byline links, but it does not erase attribution stored on articles.</p>

        <h2>Know what happens when an author is removed</h2>
        <p>You cannot remove the account you are currently using. Another administrator must handle that change. An author who owns CMS pages also cannot be removed until those pages are reassigned or deleted.</p>
        <p>When an eligible author is removed, their articles are kept. Their author assignments are removed, so review affected articles and add the correct remaining author where needed.</p>

        <h2>Add advanced author schema only when needed</h2>
        <p>The regular profile provides the starting information for author structured data. Use <strong>Edit Schema</strong> for optional expertise, awards, education, language-specific text, or additional authoritative profile links. See <strong>Configure Structured Data (Schema) and Sitemap SEO</strong> for the complete walkthrough.</p>

        <h2>A simple author checklist</h2>
        <ul>
          <li>The author can sign in with their own email.</li>
          <li>The public name, role, slug, biography, and links are accurate.</li>
          <li>Article authors appear in the intended order.</li>
          <li>Author pages are enabled only when the publication wants public profiles.</li>
          <li>Pages are reassigned before an account is removed.</li>
        </ul>
      HTML
    end

    def scheduling_article_html
      <<~HTML
        <h2>Publish at the right local time</h2>
        <p>Scheduling lets you prepare an unpublished article now and have PostnHost publish its saved draft at a future time. Set the site timezone first so editors enter and read dates consistently.</p>

        <h2>Set the site timezone</h2>
        <ol>
          <li>Open <strong>Settings</strong> and select <strong>Timezone</strong>.</li>
          <li>Choose the timezone used by your editorial team.</li>
          <li>Select <strong>Save Timezone</strong>.</li>
        </ol>
        <p>PostnHost uses this timezone for times displayed and entered in the CMS. If a distributed team publishes against one main market, choose that market’s timezone and document the choice for every editor.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/11-how-to-schedule-an-article-for-publication-01-timezone.webp')}" alt="PostnHost Timezone settings with Prague selected for the editorial workspace.">
        </div>
        <p><em>Choose the editorial timezone before selecting a publication date.</em></p>

        <h2>Schedule an unpublished article</h2>
        <ol>
          <li>Open a draft article and finish the content you want published.</li>
          <li>In the <strong>Actions</strong> sidebar, select <strong>Schedule</strong>.</li>
          <li>Choose a future date and local time.</li>
          <li>Leave the field and wait until the editor shows <strong>Saved</strong>.</li>
        </ol>
        <p>The Schedule control is available for unpublished articles. After saving, the Actions sidebar shows <strong>Scheduled publish</strong> with the chosen time. The article also appears under the <strong>Scheduled</strong> filter on the Articles page.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/11-how-to-schedule-an-article-for-publication-02-scheduled-article.webp')}" alt="PostnHost article editor showing a Scheduled publish summary for April 15, 2027 with Update and Cancel controls.">
        </div>
        <p><em>The scheduled summary confirms the saved publication time in the configured timezone.</em></p>

        <h2>Update the publication time</h2>
        <p>Select <strong>Update</strong> in the scheduled summary, choose another future time, and wait for <strong>Saved</strong>. PostnHost replaces the previous scheduled job, so only the latest saved time should be used.</p>

        <h2>Cancel a schedule</h2>
        <p>Select <strong>Cancel</strong> in the scheduled summary and wait for the editor to save. The article remains a draft and will no longer appear in the Scheduled filter. You can publish it manually or schedule it again later.</p>

        <h2>What happens at publication time</h2>
        <p>When the scheduled time arrives, PostnHost asks its background-job system to publish the saved draft. After a successful run, the article becomes public like an article published with <strong>Publish Now</strong>.</p>
        <p>Scheduling depends on the application’s background worker being available. If the time passes and the article is still a draft, refresh the editor and check <strong>Details → Timestamps</strong> for a publication error. An administrator can also check the job dashboard at <code>/jobs</code> and confirm that the publishing worker is running.</p>
      HTML
    end

    def version_history_article_html
      <<~HTML
        <h2>Return to an earlier published version</h2>
        <p>PostnHost keeps a version each time an article is published. This gives editors a dependable record of what readers could see and a safe way to bring an older version back into the editor.</p>
        <p>Versions are not created for every autosave or keystroke. Draft changes continue to save in the editor, while Version History records published moments.</p>

        <h2>Open Version History</h2>
        <ol>
          <li>Open a published article in the CMS.</li>
          <li>Open its article actions and select <strong>View History</strong>.</li>
        </ol>
        <p>The newest entry is marked <strong>Published Version</strong>. Older entries are numbered in reverse order, so you can follow how the public article changed over time.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/12-how-article-version-history-and-restores-work-01-version-history.webp')}" alt="PostnHost Version History listing a published version and two older versions with Preview and Restore actions.">
        </div>
        <p><em>Each published entry includes a preview and restore action.</em></p>

        <h2>Preview before restoring</h2>
        <p>Select <strong>Preview</strong> beside a version to inspect its title, description, and article content without changing the current draft. This is the quickest way to confirm that you have found the right version.</p>
        <p>Previewing is especially useful when several versions were published close together or have similar titles.</p>

        <h2>Restore a version to the draft</h2>
        <ol>
          <li>Select <strong>Restore</strong> beside the version you want.</li>
          <li>Read the confirmation carefully and continue only when you are ready to replace the current draft fields.</li>
          <li>Return to the editor and review the restored title, SEO fields, excerpt, content, slug, and cover-image details.</li>
        </ol>
        <p>A restore overwrites the current draft with the selected published version. Save or copy any draft work you still need before continuing.</p>

        <h2>Publish the restored draft when ready</h2>
        <p>Restoring does not immediately change the public article. Readers continue to see the current published version while you review the restored draft.</p>
        <p>When everything is correct, use <strong>Publish New Version</strong>. PostnHost publishes the restored draft and adds another entry to Version History, so the complete publishing trail remains available.</p>
      HTML
    end

    def languages_article_html
      <<~HTML
        <h2>Give every language a clear place in the CMS</h2>
        <p>A PostnHost language record tells the CMS which languages your publication supports. It also supplies the code used in localized URLs and the page’s HTML language attribute.</p>
        <p>Three related parts work together:</p>
        <ul>
          <li><strong>Language records</strong> make a language available in the CMS.</li>
          <li><strong>Content translations</strong> provide localized articles, pages, and categories.</li>
          <li><strong>Locale files or I18n overrides</strong> translate shared public text such as navigation labels and empty states.</li>
        </ul>
        <p>Adding one part does not create the other two automatically.</p>

        <h2>Add a language</h2>
        <ol>
          <li>Open <strong>Languages</strong> from the CMS navigation.</li>
          <li>Select <strong>New Language</strong>.</li>
          <li>Enter the public name, such as “Spanish.”</li>
          <li>Enter the matching language code, such as <code>es</code>.</li>
          <li>Enable <strong>Default Language</strong> only when this should be the main language for the site.</li>
          <li>Create the language.</li>
        </ol>
        <p>Keep the code short and consistent. It becomes part of localized routes such as <code>/es</code>, so changing it later can change public URLs.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/13-how-to-add-and-manage-languages-01-language-management.webp')}" alt="PostnHost Languages list showing English as the default language and Polish and Spanish with content counts.">
        </div>
        <p><em>The Languages list identifies the default language and shows original-content and translation counts.</em></p>

        <h2>Understand the default language</h2>
        <p>Every site should have one default language. It is the main publishing language and the fallback when a localized version is not being requested. Change it only as part of an intentional site-wide language and URL plan.</p>

        <h2>Use the language list and detail page</h2>
        <p>The two count badges show content written originally in that language and translated variants in that language. Select a language name or its view action to see the associated content in more detail.</p>
        <p>A language can exist before translations are ready, so a zero count is normal. Create translations separately from the article, page, or category that provides the source content.</p>
        <p>If the detail page warns that no locale file exists, the Language record is available but shared public interface text is not fully prepared for that code. Use the optional developer setup below.</p>
        <p>Before editing a code or removing a language, review its content and translations. Those changes can affect localized routes and associated records.</p>

        <h2>When no developer setup is needed</h2>
        <p>PostnHost includes public locale files for English, French, German, Japanese, Korean, Portuguese, Polish, Spanish, and Russian: <code>en</code>, <code>fr</code>, <code>de</code>, <code>ja</code>, <code>ko</code>, <code>pt</code>, <code>pl</code>, <code>es</code>, and <code>ru</code>.</p>
        <p>If the chosen code is already available in the host application, you can create the matching Language record in the dashboard, add content translations, and customize shared text under <strong>Settings → I18n</strong>.</p>

        <h2>Add more languages</h2>
        <p>This section is only for a language code that the host application does not already support. Ask a developer with access to the Rails application to complete it.</p>
        <p>Add the new code while preserving the existing locale list:</p>
        <pre><code># config/application.rb
        config.i18n.default_locale = :en
        config.i18n.available_locales = %i[en fr de ja ko pt pl es ru it]
        config.i18n.fallbacks = [:en]</code></pre>
        <p>Generate a host-application locale file for the same code:</p>
        <pre><code>bin/rails g postnhost:locale it</code></pre>
        <ol>
          <li>Translate the relevant keys under <code>postnhost.public</code> in <code>config/locales/it.yml</code>.</li>
          <li>Restart Rails after changing <code>config/application.rb</code>.</li>
          <li>Create the matching Language record in PostnHost with code <code>it</code>.</li>
          <li>Add article, page, and category translations separately.</li>
        </ol>
        <p>The Language record, <code>available_locales</code> entry, and locale filename must use the same code. A mismatch can cause missing interface text or unexpected localized routes. Keep the English fallback, or use a fallback map that eventually reaches the default language.</p>

        <h2>Verify the new language</h2>
        <ul>
          <li>Open its localized index, such as <code>/es</code> or <code>/it</code>.</li>
          <li>Check the public language switcher.</li>
          <li>Review shared text under <strong>Settings → I18n</strong>.</li>
          <li>Publish and open at least one translated content item.</li>
        </ul>
      HTML
    end

    def translations_article_html
      <<~HTML
        <h2>Publish each language on its own schedule</h2>
        <p>PostnHost keeps translated articles, pages, and categories connected to their source content while giving each translation its own draft and published state. You can prepare one language, review it, and publish it without changing the others.</p>
        <p>Before starting, add the target languages under <strong>Languages</strong>. For AI translation, publish the source article or page first.</p>

        <h2>Open the translation workspace</h2>
        <ol>
          <li>Open an article or page in the CMS.</li>
          <li>Select <strong>Translations</strong>.</li>
        </ol>
        <p>The workspace shows existing translations, their language and status, plus the languages still available. Choose <strong>Translate with AI</strong> or open <strong>Manual Translation</strong> to continue.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/14-how-to-translate-articles-pages-and-categories-01-translation-options.webp')}" alt="PostnHost Article Translations page with AI translation, manual language choices, and an existing translation.">
        </div>
        <p><em>An existing German translation is published while Polish and Spanish remain available.</em></p>

        <h2>Create translations with AI</h2>
        <p>Select <strong>Translate with AI</strong>, choose one or more languages, and start the translation. PostnHost creates a separate draft for every selected language.</p>
        <div>
          <img src="#{sample_asset_path('postnhost/sample-docs/14-how-to-translate-articles-pages-and-categories-02-ai-language-selection.webp')}" alt="PostnHost Translate with AI dialog with Polish and Spanish selected.">
        </div>
        <p><em>Select only the languages you are ready to review.</em></p>
        <p>AI translation requires an OpenAI key configured by the host application through <code>config.openai_api_key</code> or the <code>postnhost.openai_access_token</code> Rails credential. If the AI action reports that configuration is missing, ask the application administrator to enable it. Never place a real key in an article or shared note.</p>
        <p>Article AI translation uses the published source snapshot. Draft changes made after the last publication are not included until you publish a new source version.</p>

        <h2>Wait for generation, then review</h2>
        <p>A new AI translation may show a <strong>Translating</strong> state while background work is running. It cannot be edited until generation finishes. Refresh the list after a short wait if the status has not changed.</p>
        <p>Open the completed draft and review it as editorial work, not as a finished result. Check the title, title tag, social title, description, excerpt, body, links, image context, and language-specific terminology. Correct anything that sounds unnatural or changes the meaning.</p>

        <h2>Create a manual translation</h2>
        <ol>
          <li>Open <strong>Manual Translation</strong>.</li>
          <li>Select one available language.</li>
          <li>Replace the copied source fields with the translated text.</li>
          <li>Review the complete draft and publish it when ready.</li>
        </ol>
        <p>The copied source is a working starting point; it is not a translation. Manual mode works well when a translator wants the original structure visible or when AI translation is not configured.</p>

        <h2>Publish translations independently</h2>
        <p>Publishing the English article does not publish its Polish or Spanish variants, and unpublishing one translation does not automatically unpublish the others. Review each language’s status from the translation workspace.</p>
        <p>Article and page translation lists also support bulk publish, unpublish, and delete actions. Select the intended rows, choose the action, and confirm it carefully. Bulk actions are useful after a coordinated review, but independent publishing is safer when languages are approved at different times.</p>

        <h2>Translate categories</h2>
        <p>Open a category and choose its translations. Category translations use a simpler form with a localized name and description instead of the full article editor. Create and review each available language there.</p>
        <p>The article and page bulk controls do not apply to category translations. Manage category languages individually so navigation labels and category pages stay intentional.</p>

        <h2>Before publishing a language</h2>
        <ul>
          <li>The translation uses the correct Language record.</li>
          <li>The title, metadata, excerpt, and body have been reviewed by a person.</li>
          <li>Links and names make sense for the target audience.</li>
          <li>Shared public text is ready under <strong>Settings → I18n</strong>.</li>
          <li>The translation’s own status is Published.</li>
        </ul>
      HTML
    end

    def welcome_article_html
      <<~HTML
        <h2>SEO-ready multilanguage content engine for Rails</h2>
        <p>PostnHost is an open source Rails engine for adding a complete publishing workspace to a Rails application. Write, translate, and publish articles with a rich text editor, version history, and search-friendly metadata built in.</p>

        <h2>Features</h2>
        <ul>
          <li>📝 <strong>Rich text editor</strong> — TipTap-based WYSIWYG</li>
          <li>🌍 <strong>Multilingual</strong> — Translatable articles, i18n, and locale-aware SEO metadata</li>
          <li>🖼️ <strong>Image management</strong> — CarrierWave with S3-compatible storage</li>
          <li>📊 <strong>Version history</strong> — Article versions and rollback</li>
          <li>🤖 <strong>Suggested articles</strong> — Manual picks plus automatic suggestions from related categories</li>
          <li>⏰ <strong>Post scheduling</strong> — Schedule publication through your application’s Active Job adapter</li>
          <li>🌐 <strong>Localized SEO</strong> — Localized routes, language switcher, sitemap, and hreflang tags</li>
          <li>⚙️ <strong>Settings</strong> — Update key copy and assets from the CMS</li>
          <li>🎨 <strong>Customizable views</strong> — Override public templates in the host app (<code>rails g postnhost:views</code>)</li>
          <li>⚡ <strong>Hotwire UI</strong> — Turbo Frames/Streams and Stimulus</li>
          <li>🔐 <strong>Session-based auth</strong> — Built-in admin authentication</li>
        </ul>

        <h2>Tech stack</h2>
        <table>
          <thead>
            <tr>
              <th><p>Component</p></th>
              <th><p>Technology</p></th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><p>Framework</p></td>
              <td><p>Rails</p></td>
            </tr>
            <tr>
              <td><p>Versioning</p></td>
              <td><p>PaperTrail</p></td>
            </tr>
            <tr>
              <td><p>Frontend</p></td>
              <td><p>Hotwire (Turbo + Stimulus), TailwindCSS</p></td>
            </tr>
            <tr>
              <td><p>Editor</p></td>
              <td><p>Tiptap</p></td>
            </tr>
            <tr>
              <td><p>File storage</p></td>
              <td><p>CarrierWave (S3 compatible)</p></td>
            </tr>
            <tr>
              <td><p>Background jobs</p></td>
              <td><p>Active Job</p></td>
            </tr>
          </tbody>
        </table>

        <h2>Add PostnHost to a Rails application</h2>
        <p>Add the gem to the host application’s <code>Gemfile</code>:</p>
        <pre><code class="language-ruby">gem "postnhost"</code></pre>
        <p>Install the gem, generate the initializer and mount route, then copy and run the engine migrations:</p>
        <pre><code class="language-bash">bundle install
        bin/rails g postnhost:install
        bin/rails postnhost:install:migrations
        bin/rails db:migrate</code></pre>
        <p>Start the host application and open PostnHost’s onboarding page below the configured mount path. The installer uses <code>/blog/onboarding</code> by default. Create the first CMS administrator there and choose whether to add this sample documentation.</p>

        <h2>Configuration</h2>
        <p>Configure PostnHost in <code>config/initializers/postnhost.rb</code>. Site URL, pagination, and timezone can also be managed from <strong>Settings</strong> in the CMS.</p>
        <p>Rails credentials can be used as an alternative to defining matching values in the initializer.</p>
        <p>Update <code>public/robots.txt</code> so the <code>Sitemap:</code> URL matches your deployment—the path depends on where the engine is mounted (for example <code>/sitemap.xml</code> vs a <code>/blog</code> prefix).</p>

        <h2>Open source</h2>
        <p>Distributed under the MIT License.</p>
      HTML
    end

    def sample_asset_path(logical_path)
      ActionController::Base.helpers.asset_path(logical_path)
    end

    def resolve_cover_image_source(cover_image_path)
      return if cover_image_path.blank?

      candidates = [Rails.root.join(cover_image_path)]

      candidates << Postnhost::Engine.root.join(cover_image_path) if defined?(Postnhost::Engine)
      candidates << Rails.root.join("app/assets/images/postnhost/og-image.webp")
      candidates << Postnhost::Engine.root.join("app/assets/images/postnhost/og-image.webp") if defined?(Postnhost::Engine)

      candidates.find(&:file?)
    end
  end
end
