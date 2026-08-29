require "bcrypt"
require "carrierwave"
require "carrierwave-aws"
require "nokogiri"
require "openai"
require "pagy"
require "paper_trail"
require "ruby-vips"

require_relative "postnhost/version"
require_relative "postnhost/configuration"
require_relative "postnhost/settings/i18n_overrides"
require_relative "postnhost/sample_data"
require_relative "postnhost/settings/i18n_patch"
require_relative "postnhost/engine" if defined?(Rails::Engine)

module Postnhost
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    configuration
  end

  def self.config
    configuration || configure
  end
end
