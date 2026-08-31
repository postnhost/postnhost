require "rails_helper"
require "postnhost/css_scope"

RSpec.describe Postnhost::CssScope do
  it "scopes root, utility, custom, and nested selectors" do
    css = <<~CSS
      :root, :host { --color: red; }
      html { line-height: 1.5; }
      :root .root-child { color: red; }
      *, ::before { box-sizing: border-box; }
      .flex, .prose :where(p, ul) { display: flex; }
      @media (width >= 48rem) { .md\\:grid { display: grid; } }
      @keyframes spin { to { transform: rotate(360deg); } }
    CSS

    scoped_css = described_class.call(css)

    expect(scoped_css).to include("html[data-postnhost]{ --color: red;")
    expect(scoped_css).to include("html[data-postnhost]{ line-height: 1.5;")
    expect(scoped_css).to include("html[data-postnhost] .root-child")
    expect(scoped_css).to include(":is(html[data-postnhost], html[data-postnhost] *)")
    expect(scoped_css).to include(":is(html[data-postnhost], html[data-postnhost] *).flex")
    expect(scoped_css).to include(":is(html[data-postnhost], html[data-postnhost] *).prose :where(p, ul)")
    expect(scoped_css).to include(":is(html[data-postnhost], html[data-postnhost] *).md\\:grid")
    expect(scoped_css).to include("@keyframes spin { to { transform: rotate(360deg); } }")
    expect(scoped_css).not_to include("html[data-postnhost] :root")
  end

  it "does not treat custom elements beginning with html as the document root" do
    scoped_css = described_class.call("html-editor { display: block; }")

    expect(scoped_css).to include("html[data-postnhost] html-editor")
  end
end
