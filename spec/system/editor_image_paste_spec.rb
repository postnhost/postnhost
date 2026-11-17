require "rails_helper"

RSpec.describe "Editor image paste", type: :system do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user, password: "password", password_confirmation: "password") }
  let(:image_data) { File.binread(Postnhost::Engine.root.join("spec/fixtures/files/cover_image.webp")) }

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with("example.com").and_return(["1.1.1.1"])
    sign_in_as(user)
  end

  %i[article page].each do |resource_type|
    context "with a #{resource_type}" do
      let(:record) { create(resource_type, user:, content: "") }

      before { visit postnhost.public_send("edit_#{resource_type}_path", record) }

      it "uploads embedded and remote images, preserving surrounding formatting and order" do
        stub_request(:get, "https://example.com/pasted.webp").to_return(body: image_data, headers: { "Content-Type" => "image/webp" })
        html = <<~HTML
          <p><strong>Before images</strong></p>
          <img src="data:image/webp;base64,#{Base64.strict_encode64(image_data)}" alt="Embedded image" width="300">
          <p>Between images</p>
          <img src="https://example.com/pasted.webp" srcset="https://example.com/other.webp 2x" alt="Remote image">
          <p>After images</p>
        HTML

        paste_html(html, image_data)

        expect(page).to have_css('.ProseMirror img[src*="/inline_images/"]', count: 2)
        expect(page).to have_css(".ProseMirror strong", text: "Before images")
        expect(page).to have_css('.ProseMirror img[alt="Embedded image"][width="300"]')
        content = find("input[name='#{resource_type}[content]']", visible: :all).value
        expect(content).not_to include("data:image", "example.com", "srcset")
        fragment = Nokogiri::HTML.fragment(content)
        expect(fragment.css("p, img").map { |node| node.name == "img" ? node["alt"] : node.text }).to eq(
          ["Before images", "Embedded image", "Between images", "Remote image", "After images"]
        )
      end

      it "uploads every clipboard image file" do
        page.execute_script(<<~JS, Base64.strict_encode64(image_data))
          const bytes = Uint8Array.from(atob(arguments[0]), character => character.charCodeAt(0))
          const clipboard = new DataTransfer()
          clipboard.items.add(new File([bytes], 'first.webp', { type: 'image/webp' }))
          clipboard.items.add(new File([bytes], 'second.webp', { type: 'image/webp' }))
          document.querySelector('.ProseMirror').dispatchEvent(new ClipboardEvent('paste', {
            clipboardData: clipboard, bubbles: true, cancelable: true
          }))
        JS

        expect(page).to have_css('.ProseMirror img[src*="/inline_images/"]', count: 2)
      end

      it "keeps text and reports failed imports without retaining the original image URL" do
        stub_request(:get, "https://example.com/broken.png").to_return(status: 404)

        accept_alert("Some pasted images could not be uploaded. Please try pasting those images again.") do
          paste_html('<p>Retained text</p><img src="https://example.com/broken.png" alt="Missing image">')
        end

        expect(page).to have_css(".ProseMirror", text: "Retained text")
        expect(page).to have_no_css(".ProseMirror img")
        content = find("input[name='#{resource_type}[content]']", visible: :all).value
        expect(content).not_to include("example.com")
      end
    end
  end

  def paste_html(html, clipboard_image = nil)
    page.execute_script(<<~JS, html, clipboard_image && Base64.strict_encode64(clipboard_image))
      const clipboard = new DataTransfer()
      clipboard.setData('text/html', arguments[0])
      if (arguments[1]) {
        const bytes = Uint8Array.from(atob(arguments[1]), character => character.charCodeAt(0))
        clipboard.items.add(new File([bytes], 'duplicate.webp', { type: 'image/webp' }))
      }
      document.querySelector('.ProseMirror').dispatchEvent(new ClipboardEvent('paste', {
        clipboardData: clipboard, bubbles: true, cancelable: true
      }))
    JS
  end
end
