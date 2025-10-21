FactoryBot.define do
  factory :camp_configuration do
    sequence(:camp_year) { |n| 2025 + n }

    application_open { Date.new(camp_year, 1, 1) }
    application_close { Date.new(camp_year, 10, 31) }
    priority { Date.new(camp_year, 4, 1) }
    application_materials_due { Date.new(camp_year, 5, 20) }
    camper_acceptance_due { Date.new(camp_year, 6, 1) }
    application_fee_cents { 10_000 }
    application_fee_required { true }
    active { false }
    offer_letter { 'Default offer letter content' }
    reject_letter { 'Default rejection letter content' }
    waitlist_letter { 'Default waitlist letter content' }

    trait :active do
      active { true }
    end

    trait :current_year do
      camp_year { Date.current.year }
      active { true }
    end

    trait :next_year do
      camp_year { Date.current.year + 1 }
      active { false }
    end

    trait :no_application_fee do
      application_fee_required { false }
      application_fee_cents { 0 }
    end

    trait :with_sessions do
      after(:create) do |camp_config|
        create_list(:camp_occurrence, 3, camp_configuration: camp_config, active: true)
      end
    end
  end
end
