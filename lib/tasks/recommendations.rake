# frozen_string_literal: true

namespace :recommendations do
  desc 'Issue upload tokens to recommendations still waiting for a letter that have none (post-deploy sweep; sends no email)'
  task issue_missing_upload_tokens: :environment do
    scope = Recommendation.where(upload_token: nil).where.missing(:recupload)
    issued = 0
    scope.find_each do |recommendation|
      # Re-checked under the row lock: an admin resend that lands meanwhile is left alone.
      issued += 1 if recommendation.issue_upload_token!(only_if_missing: true)
    rescue Recommendation::LetterAlreadyReceived
      next
    end
    puts "Issued upload tokens to #{issued} #{'recommendation'.pluralize(issued)}."
  end
end
