# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::Comment, type: :model do
  it 'uses the ActiveAdmin comments table and defaults to the admin namespace' do
    expect(described_class.table_name).to eq('active_admin_comments')
    expect(described_class.new.namespace).to eq('admin')
  end

  it 'requires a body' do
    comment = described_class.new(body: '', author: build(:admin), resource: build(:enrollment))

    expect(comment).not_to be_valid
    expect(comment.errors[:body]).to include("can't be blank")
  end

  describe '.commentable_class' do
    it 'resolves registered models only' do
      expect(described_class.commentable_class('Enrollment')).to eq(Enrollment)
      expect(described_class.commentable_class('Admin')).to be_nil
      expect(described_class.commentable_class('Kernel')).to be_nil
      expect(described_class.commentable_class(nil)).to be_nil
    end

    it 'only lists models that include AdminCommentable' do
      described_class::COMMENTABLE_MODELS.each_value do |resolver|
        expect(resolver.call).to include(AdminCommentable)
      end
    end
  end
end
