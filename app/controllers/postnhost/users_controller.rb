module Postnhost
  class UsersController < ApplicationController
    include Postnhost::Users::SchemaManageable

    before_action :authenticate_user!
    before_action :load_user, only: %i[edit update destroy schema_edit schema_update]
    layout "postnhost/product"

    def index
      @users = Postnhost::User.order(:name, :email)
    end

    def new
      @user = Postnhost::User.new
    end

    def edit; end

    def schema_edit
      set_user_schema_editor_state
    end

    def create
      @user = Postnhost::User.new(user_params)

      if @user.save
        redirect_to users_path
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @user.update(user_params)
        redirect_to edit_user_path(@user), notice: "Author was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def schema_update
      @schema_locale_keys = user_schema_locale_keys
      locale_key = selected_user_schema_locale_key
      merged_profile = @user.schema_profile_hash.merge(user_schema_profile_params)
      merged_overrides = merge_user_schema_locale_overrides(
        @user.schema_locale_overrides_hash,
        locale_key,
        user_schema_translation_params
      )

      if @user.update(schema_profile: merged_profile, schema_locale_overrides: merged_overrides)
        redirect_to schema_edit_user_path(@user, locale: locale_key), notice: "Author schema was successfully updated."
      else
        set_user_schema_editor_state
        @schema_profile_values = merged_profile
        @schema_translation_entries = @schema_translation_entries.merge(user_schema_translation_params.stringify_keys)
        render :schema_edit, status: :unprocessable_content
      end
    end

    def destroy
      if @user == current_user
        redirect_to users_path, alert: "You cannot remove your own account while signed in."
        return
      end

      if @user.pages.exists?
        redirect_to users_path, alert: "Author cannot be removed while they own pages. Reassign or remove their pages first."
        return
      end

      Postnhost::User.transaction do
        Postnhost::Article.where(user_id: @user.id).update_all(user_id: nil, updated_at: Time.current)
        @user.article_authors.delete_all
        @user.destroy!
      end

      redirect_to users_path, notice: "Author was successfully removed. Their articles were kept."
    end

    private

    def load_user
      @user = Postnhost::User.find(params[:id])
    end

    def user_params
      attrs = params.require(:user).permit(
        :email,
        :name,
        :slug,
        :position,
        :bio,
        :website_url,
        :x_url,
        :linkedin_url,
        :threads_url,
        :tiktok_url,
        :youtube_url,
        :facebook_url,
        :instagram_url,
        :bluesky_url,
        :mastodon_url,
        :avatar_file,
        :password,
        :password_confirmation
      )
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
      attrs
    end
  end
end
