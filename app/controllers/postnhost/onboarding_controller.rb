module Postnhost
  class OnboardingController < ApplicationController
    include Postnhost::Onboarding::AccessControl
    include Postnhost::Onboarding::StepAssignment

    layout "postnhost/application"

    before_action :ensure_onboarding_allowed!
    before_action :synchronize_onboarding_session

    def show
      @post_install_checklist = post_install_checklist_mode?
      return if @post_install_checklist

      @step = current_step
      load_step_assignments
    end

    def update
      handle_step_result(Postnhost::Onboarding::StepProcessor.call(params:, session:))
    end

    private

    def handle_step_result(result)
      payload = result.value || {}

      case result.status
      when :redirect_onboarding then redirect_to_onboarding(payload[:alert])
      when :redirect_new_session then redirect_to postnhost.new_session_path, alert: payload[:alert]
      when :render_show then render_step(payload:, result:)
      when :finish_setup then finish_setup(payload.fetch(:user))
      when :redirect_articles then redirect_to postnhost.articles_path
      else redirect_to_onboarding("Invalid onboarding response.")
      end
    end

    def redirect_to_onboarding(alert = nil)
      if alert.present?
        redirect_to postnhost.onboarding_path, alert:
      else
        redirect_to postnhost.onboarding_path
      end
    end

    def render_step(payload:, result:)
      assign_step_payload(payload)
      flash.now[:alert] = payload[:alert] || result.errors.first if payload[:alert].present? || result.errors.first.present?
      render :show, status: :unprocessable_content
    end

    def assign_step_payload(payload)
      @step = payload[:step] if payload.key?(:step)
      @user = payload[:user] if payload.key?(:user)
      @language_options = payload[:language_options] if payload.key?(:language_options)
      @selected_language_locales = payload[:selected_language_locales] if payload.key?(:selected_language_locales)
      @selected_default_locale = payload[:selected_default_locale] if payload.key?(:selected_default_locale)
      @locale = payload[:locale] if payload.key?(:locale)
      @site_url = payload[:site_url] if payload.key?(:site_url)
      @site_indexing = payload[:site_indexing] if payload.key?(:site_indexing)
      @site_copy = payload[:site_copy] if payload.key?(:site_copy)
    end

    def finish_setup(user)
      sign_in(user)
      session[:onboarding_post_install_checklist] = true
      redirect_to postnhost.onboarding_path(post_install: "1")
    end
  end
end
