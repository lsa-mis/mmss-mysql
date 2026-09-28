# frozen_string_literal: true

# `expect(response.body).to include_unescaped("O'Neil, Ada")`
#
# Views HTML-escape everything they render, so an apostrophe in a Faker name (`D'Amore`,
# `O'Connell`) or in a validation message (`can't be blank`) appears in the body as `&#39;`.
# Asserting `include(text)` on the raw body then fails only for the ~3% of generated names that
# carry one — a flake. This matcher unescapes the body before comparing, so the assertion reads
# the way the page does.
RSpec::Matchers.define :include_unescaped do |*expected|
  match do |actual|
    unescaped = CGI.unescapeHTML(actual.to_s)
    expected.all? { |text| unescaped.include?(text) }
  end

  match_when_negated do |actual|
    unescaped = CGI.unescapeHTML(actual.to_s)
    expected.none? { |text| unescaped.include?(text) }
  end

  failure_message do |actual|
    missing = expected.reject { |text| CGI.unescapeHTML(actual.to_s).include?(text) }
    "expected the HTML-unescaped body to include #{missing.map(&:inspect).join(', ')}"
  end

  failure_message_when_negated do |actual|
    present = expected.select { |text| CGI.unescapeHTML(actual.to_s).include?(text) }
    "expected the HTML-unescaped body not to include #{present.map(&:inspect).join(', ')}"
  end
end
