require "rouge"

module Postnhost
  module ArticleHelper
    def render_article_content(content)
      # Add <br> to empty <p> tags to match editor behavior
      content = content&.gsub("<p></p>", "<p><br></p>")
      content = content&.gsub(%r{<p>\s*</p>}, "<p><br></p>")

      sanitized_content = sanitize(
        content,
        tags: %w[p h1 h2 h3 h4 h5 h6 strong em u s sup sub mark code pre span blockquote ul ol li a img table colgroup col thead tbody tr th td br
                 hr div iframe],
        attributes: %w[href src alt class style target rel width height colspan rowspan frameborder allow allowfullscreen title]
      )

      highlight_code_blocks(sanitized_content)
    end

    def article_excerpt(article)
      article.custom_excerpt.presence || article.auto_excerpt.presence
    end

    private

    def highlight_code_blocks(content)
      fragment = Nokogiri::HTML5.fragment(content)
      formatter = Rouge::Formatters::HTML.new

      fragment.css("pre > code[class]").each do |code_block|
        language = code_block["class"].to_s.split.filter_map { |class_name| class_name.delete_prefix("language-") if class_name.start_with?("language-") }.first
        lexer = Rouge::Lexer.find(language)&.new
        next unless lexer

        code_block.inner_html = formatter.format(lexer.lex(code_block.text))
      end

      fragment.to_html.html_safe
    end
  end
end
