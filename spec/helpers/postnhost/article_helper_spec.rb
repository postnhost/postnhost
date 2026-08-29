require "rails_helper"

RSpec.describe Postnhost::ArticleHelper, type: :helper do
  describe "#render_article_content" do
    it "highlights code blocks with an explicit language" do
      content = '<pre><code class="language-ruby">def greet\n  puts &quot;Hello&quot;\nend</code></pre>'

      rendered_content = helper.render_article_content(content)
      document = Nokogiri::HTML5.fragment(rendered_content)

      expect(document.at_css("code.language-ruby .k").text).to eq("def")
      expect(document.at_css("code.language-ruby .nb").text).to eq("puts")
      expect(document.at_css("code.language-ruby").text).to include('puts "Hello"')
    end

    it "keeps plain text code blocks unhighlighted" do
      content = '<pre><code class="language-plaintext">Use &lt;strong&gt; tags</code></pre>'

      rendered_content = helper.render_article_content(content)
      document = Nokogiri::HTML5.fragment(rendered_content)

      expect(document.at_css("code.language-plaintext span")).to be_nil
      expect(document.at_css("code.language-plaintext").text).to eq("Use <strong> tags")
    end

    it "sanitizes content before adding syntax markup" do
      content = '<pre><code class="language-javascript">alert(&quot;safe&quot;)</code></pre><script>alert("unsafe")</script>'

      rendered_content = helper.render_article_content(content)

      expect(rendered_content).to include("<span")
      expect(rendered_content).not_to include("<script")
    end
  end

  describe "#article_excerpt" do
    it "returns custom excerpt when present" do
      resource = Struct.new(:custom_excerpt, :auto_excerpt).new(
        "Custom excerpt",
        "Auto excerpt"
      )

      excerpt = helper.article_excerpt(resource)

      expect(excerpt).to eq("Custom excerpt")
    end

    it "falls back to auto excerpt when custom excerpt is blank" do
      resource = Struct.new(:custom_excerpt, :auto_excerpt).new(
        nil,
        "Auto excerpt"
      )

      excerpt = helper.article_excerpt(resource)

      expect(excerpt).to eq("Auto excerpt")
    end
  end
end
