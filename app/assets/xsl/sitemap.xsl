<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:sitemap="http://www.sitemaps.org/schemas/sitemap/0.9"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="sitemap xhtml">

  <xsl:output method="html" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta name="robots" content="noindex, nofollow"/>
        <title>Sitemap</title>
        <style>
          body { font-family: system-ui, -apple-system, Segoe UI, sans-serif; margin: 1.5rem; color: #111827; line-height: 1.5; }
          h1 { font-size: 1.25rem; font-weight: 600; margin: 0 0 1rem; }
          p.meta { font-size: 0.875rem; color: #6b7280; margin-bottom: 1rem; }
          table { width: 100%; border-collapse: collapse; font-size: 0.8125rem; }
          th, td { border: 1px solid #e5e7eb; padding: 0.5rem 0.75rem; text-align: left; vertical-align: top; word-break: break-word; }
          th { background: #f9fafb; font-weight: 600; }
          tbody tr:nth-child(even) td { background: #fafafa; }
          a { color: #2563eb; text-decoration: underline; }
          a:hover { color: #1d4ed8; }
          .alt { display: block; margin: 0.15rem 0; }
          code { font-size: 0.85em; background: #f3f4f6; padding: 0.1em 0.35em; border-radius: 0.25rem; }
        </style>
      </head>
      <body>
        <h1>Sitemap</h1>
        <table>
          <thead>
            <tr>
              <th scope="col">URL</th>
              <th scope="col">Last modified</th>
              <th scope="col">Alternates</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="sitemap:urlset/sitemap:url">
              <tr>
                <td>
                  <a href="{sitemap:loc}"><xsl:value-of select="sitemap:loc"/></a>
                </td>
                <td><xsl:value-of select="sitemap:lastmod"/></td>
                <td>
                  <xsl:for-each select="xhtml:link">
                    <span class="alt">
                      <code><xsl:value-of select="@hreflang"/></code>
                      <xsl:text> </xsl:text>
                      <a href="{@href}"><xsl:value-of select="@href"/></a>
                    </span>
                  </xsl:for-each>
                </td>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
