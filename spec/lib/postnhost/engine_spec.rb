require "rails_helper"

RSpec.describe Postnhost::Engine do
  describe "JavaScript assets" do
    it "does not register a service worker on the host application" do
      javascript_paths = [
        described_class.root.join("app/javascript/application.js"),
        described_class.root.join("app/assets/builds/postnhost/application.js")
      ]

      aggregate_failures do
        javascript_paths.each do |path|
          expect(path.read).not_to include("serviceWorker.register")
        end
      end
    end
  end
end
