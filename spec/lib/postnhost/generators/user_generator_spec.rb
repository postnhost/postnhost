require "rails_helper"
require "rails/generators"
require "generators/postnhost/user/user_generator"

RSpec.describe Postnhost::Generators::UserGenerator do
  subject(:generator) { described_class.new([], {}, shell:) }

  let(:shell) { shell_class.new(answers) }
  let(:answers) do
    {
      "Name:" => "Admin User",
      "Email:" => "ADMIN@example.com",
      "Password:" => "secret12",
      "Confirm password:" => "secret12"
    }
  end
  let(:shell_class) do
    Class.new do
      attr_accessor :base
      attr_reader :messages, :prompts

      def initialize(answers)
        @answers = answers
        @messages = []
        @prompts = []
      end

      def ask(statement, *options)
        prompts << [statement, *options]
        @answers.fetch(statement)
      end

      def say(message = "", color = nil, *)
        messages << [message, color]
      end
    end
  end

  describe "#create_user" do
    it "creates a user while capturing both password prompts without echo" do
      generator.create_user

      user = Postnhost::User.find_by!(email: "admin@example.com")
      expect(user.name).to eq("Admin User")
      expect(user.authenticate("secret12")).to eq(user)
      expect(shell.prompts).to include(
        ["Password:", { echo: false }],
        ["Confirm password:", { echo: false }]
      )
      expect(shell.messages).to include(["Created CMS user admin@example.com.", :green])
    end

    it "rejects mismatched passwords without creating a user" do
      answers["Confirm password:"] = "different12"

      expect { generator.create_user }.to raise_error(Thor::Error, "Passwords do not match.")
      expect(Postnhost::User.exists?).to be(false)
    end
  end
end
