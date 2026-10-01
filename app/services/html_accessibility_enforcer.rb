# frozen_string_literal: true

# app/services/html_accessibility_enforcer.rb
class HtmlAccessibilityEnforcer
  def self.process(html)
    return html if html.blank?

    doc = Nokogiri::HTML5.fragment(html)

    doc.css('a[target="_blank"]').each do |link|
      # Prevent tab-napping
      rel = (link['rel'] || '').split.to_set
      rel << 'noopener' << 'noreferrer'
      link['rel'] = rel.to_a.join(' ')

      # Add aria-label if missing
      unless link['aria-label'].present?
        link['aria-label'] = "#{link.text.strip} (opens in a new tab)"
      end
    end

    doc.to_html
  end
end
