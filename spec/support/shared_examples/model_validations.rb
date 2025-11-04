# frozen_string_literal: true

# Shared examples for common model validations

RSpec.shared_examples 'a model with timestamps' do
  it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
  it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
end

RSpec.shared_examples 'a model with required associations' do |associations|
  associations.each do |association|
    it { is_expected.to belong_to(association).required }
  end
end

RSpec.shared_examples 'a model with optional associations' do |associations|
  associations.each do |association|
    it { is_expected.to belong_to(association).optional }
  end
end

RSpec.shared_examples 'a model with required presence validations' do |attributes|
  attributes.each do |attribute|
    it { is_expected.to validate_presence_of(attribute) }
  end
end

RSpec.shared_examples 'a model with uniqueness validations' do |attributes|
  attributes.each do |attribute, scope|
    if scope
      it { is_expected.to validate_uniqueness_of(attribute).scoped_to(scope) }
    else
      it { is_expected.to validate_uniqueness_of(attribute) }
    end
  end
end

RSpec.shared_examples 'a model with length validations' do |validations|
  validations.each do |attribute, constraints|
    if constraints[:minimum]
      it { is_expected.to validate_length_of(attribute).is_at_least(constraints[:minimum]) }
    end
    if constraints[:maximum]
      it { is_expected.to validate_length_of(attribute).is_at_most(constraints[:maximum]) }
    end
  end
end

RSpec.shared_examples 'a model with has_many associations' do |associations|
  associations.each do |association|
    it { is_expected.to have_many(association).dependent(:destroy) }
  end
end

RSpec.shared_examples 'a model with has_one association' do |associations|
  associations.each do |association|
    it { is_expected.to have_one(association).dependent(:destroy) }
  end
end

RSpec.shared_examples 'a model with attached files' do |attachments|
  attachments.each do |attachment|
    it { is_expected.to have_one_attached(attachment) }
  end
end
