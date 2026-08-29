Postnhost::Engine.routes.draw do
  # Public routes
  root "public/articles#index"

  # Sitemap
  get "sitemap.xml", to: "sitemap#show", defaults: { format: "xml" }
  get "sitemap.xsl", to: "sitemap#stylesheet", defaults: { format: "xsl" }

  get "/search", to: "public/articles#search", as: :public_search

  get "/authors/:slug", to: "public/authors#show", as: :public_author

  # Public articles routes (non-localized)
  get "/:category_slug", to: "public/categories#index", as: :public_category,
                         constraints: Postnhost::Constraints::PublicRouteConstraint.new(kind: :category, parameter: :category_slug)

  get "/:slug", to: "public/articles#show", as: :public_article,
                constraints: Postnhost::Constraints::PublicRouteConstraint.new(kind: :article, parameter: :slug)

  # Localized routes
  scope "/:locale", constraints: Postnhost::Constraints::PublicLocaleConstraint do
    get "/", to: "public/articles#index", as: :localized_root
    get "/search", to: "public/articles#search", as: :localized_public_search

    get "/authors/:slug", to: "public/authors#show", as: :localized_public_author

    get "/:category_slug", to: "public/categories#index", as: :localized_public_category,
                           constraints: Postnhost::Constraints::PublicRouteConstraint.new(kind: :category,
                                                                                          parameter: :category_slug)
    get "/:slug", to: "public/articles#show", as: :localized_public_article,
                  constraints: Postnhost::Constraints::PublicRouteConstraint.new(kind: :article, parameter: :slug)
    get "/:slug", to: "public/static_pages#show", as: :localized_public_static_page
  end

  # Admin routes
  resource :onboarding, only: %i[show update], controller: "onboarding"
  resource :session, only: %i[new create destroy], controller: "sessions"
  resources :users, only: %i[index new create edit update destroy] do
    member do
      get :schema_edit
      patch :schema_update
    end
  end

  resources :articles, only: %i[index new edit update destroy] do
    member do
      get :versions
      get "versions/:version_id/preview", to: "articles#version_preview", as: :version_preview
      post :rollback
      patch :publish
      patch :unpublish
    end

    resources :images, only: %i[create], controller: "articles/images"
    resource :cover_image, only: %i[create destroy], controller: "articles/cover_images"

    resources :variants, only: %i[index new edit update destroy], controller: "article_variants" do
      collection do
        patch :bulk_publish
        patch :bulk_unpublish
        delete :bulk_destroy
      end
      member do
        patch :publish
        patch :unpublish
      end
    end

    resources :translations, only: %i[new create], controller: "articles/translations"
  end

  resources :pages, only: %i[index new edit update destroy] do
    member do
      patch :publish
      patch :unpublish
    end

    resources :images, only: %i[create], controller: "pages/images"

    resources :variants, only: %i[index new edit update destroy], controller: "page_variants" do
      collection do
        patch :bulk_publish
        patch :bulk_unpublish
        delete :bulk_destroy
      end
      member do
        patch :publish
        patch :unpublish
      end
    end

    resources :translations, only: %i[new create], controller: "pages/translations"
  end

  get "preview/:id", to: "public/articles#preview", as: :preview_article

  resources :categories do
    resources :translations, only: %i[create], controller: "categories/translations"
    resources :variants, only: %i[index new create edit update destroy], controller: "category_variants"
  end

  resources :languages
  resource :template, only: %i[edit update], controller: "templates"

  resource :settings, only: %i[edit update], controller: "settings" do
    resources :site_scripts, only: %i[create update destroy], controller: "settings/site_scripts"
  end

  # Public static pages from host app views:
  # app/views/postnhost/static_pages/*.html.erb
  get "/:slug", to: "public/static_pages#show", as: :public_static_page
end
