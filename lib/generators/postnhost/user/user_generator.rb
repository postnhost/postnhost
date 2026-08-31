module Postnhost
  module Generators
    class UserGenerator < Rails::Generators::Base
      desc "Interactively creates a PostnHost CMS user"

      def create_user
        attributes = prompt_for_user_attributes
        raise Thor::Error, "Passwords do not match." unless matching_passwords?(attributes)

        user = Postnhost::User.new(attributes)
        raise Thor::Error, user.errors.full_messages.to_sentence unless user.save

        say("Created CMS user #{user.email}.", :green)
      end

      private

      def prompt_for_user_attributes
        {
          name: ask("Name:"),
          email: ask("Email:"),
          password: ask_for_secret("Password:"),
          password_confirmation: ask_for_secret("Confirm password:")
        }
      end

      def ask_for_secret(prompt)
        ask(prompt, echo: false).tap { say "" }
      end

      def matching_passwords?(attributes)
        attributes[:password] == attributes[:password_confirmation]
      end
    end
  end
end
