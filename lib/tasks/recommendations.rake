# frozen_string_literal: true

namespace :recommendations do
  desc 'Issue upload tokens to recommendations still waiting for a letter that have none (post-deploy sweep; sends no email)'
  task issue_missing_upload_tokens: :environment do
    scope = Recommendation.where(upload_token: nil).where.missing(:recupload)
    issued = 0
    scope.find_each do |recommendation|
      recommendation.issue_upload_token!
      issued += 1
    rescue Recommendation::LetterAlreadyReceived
      next
    end
    puts "Issued upload tokens to #{issued} #{'recommendation'.pluralize(issued)}."
  end
end
