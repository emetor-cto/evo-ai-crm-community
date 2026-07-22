# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamFolder, type: :model do
  it 'requires a name and created_by_id' do
    folder = described_class.new
    expect(folder).not_to be_valid
    expect(folder.errors[:name]).to be_present
    expect(folder.errors[:created_by_id]).to be_present
  end

  it 'rejects parent_id equal to itself' do
    folder = described_class.create!(name: 'Root', created_by_id: SecureRandom.uuid)
    folder.parent_id = folder.id
    expect(folder).not_to be_valid
    expect(folder.errors[:parent_id]).to be_present
  end
end

RSpec.describe TeamDocument, type: :model do
  it 'requires a title and created_by_id' do
    document = described_class.new(title: '')
    expect(document).not_to be_valid
    expect(document.errors[:title]).to be_present
    expect(document.errors[:created_by_id]).to be_present
  end

  it 'extracts plain text from BlockNote content_json on save' do
    document = described_class.create!(
      title: 'Playbook',
      created_by_id: SecureRandom.uuid,
      content_json: [
        {
          'id' => '1',
          'type' => 'paragraph',
          'content' => [{ 'type' => 'text', 'text' => 'Hello team' }]
        }
      ]
    )

    expect(document.content_text).to include('Hello team')
  end

  it 'searches by title and content_text' do
    described_class.create!(title: 'Alpha', created_by_id: SecureRandom.uuid, content_text: 'zzz')
    match = described_class.create!(
      title: 'Beta',
      created_by_id: SecureRandom.uuid,
      content_json: [
        {
          'id' => '1',
          'type' => 'paragraph',
          'content' => [{ 'type' => 'text', 'text' => 'unique-needle-xyz' }]
        }
      ]
    )

    expect(described_class.search('unique-needle-xyz')).to contain_exactly(match)
  end
end
