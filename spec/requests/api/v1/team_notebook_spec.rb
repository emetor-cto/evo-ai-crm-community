# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'Api::V1::Team Notebook', type: :request do
  let(:base_url) { 'http://auth.test' }
  let(:validate_url) { "#{base_url}/api/v1/auth/validate" }
  let(:token) { 'test-bearer-token' }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }
  let!(:user) { User.create!(name: 'Notebook User', email: "notebook-#{SecureRandom.hex(4)}@example.com") }

  around do |example|
    original_base_url = ENV['EVO_AUTH_SERVICE_URL']
    ENV['EVO_AUTH_SERVICE_URL'] = base_url
    Rails.cache.clear
    Current.reset
    example.run
    Rails.cache.clear
    Current.reset
    ENV['EVO_AUTH_SERVICE_URL'] = original_base_url
  end

  before do
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(
        status: 200,
        body: {
          success: true,
          data: {
            user: { id: user.id, email: user.email }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    permission_check_url = "#{base_url}/api/v1/users/#{user.id}/check_permission"
    stub_request(:post, permission_check_url)
      .to_return(
        status: 200,
        body: {
          success: true,
          data: { has_permission: true }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    Current.user = user
  end

  describe 'folders' do
    it 'creates and lists a folder tree' do
      post '/api/v1/team_folders',
           params: { team_folder: { name: 'Playbooks' } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:created)
      folder_id = JSON.parse(response.body).dig('data', 'id')
      expect(folder_id).to be_present

      get '/api/v1/team_folders', params: { tree: true }, headers: headers
      expect(response).to have_http_status(:ok)
      names = JSON.parse(response.body)['data'].map { |f| f['name'] }
      expect(names).to include('Playbooks')
    end
  end

  describe 'documents' do
    it 'creates, updates and shows a document' do
      post '/api/v1/team_documents',
           params: { team_document: { title: 'Onboarding' } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:created)
      doc_id = JSON.parse(response.body).dig('data', 'id')

      patch "/api/v1/team_documents/#{doc_id}",
            params: {
              team_document: {
                title: 'Onboarding v2',
                content_json: [
                  {
                    id: '1',
                    type: 'paragraph',
                    content: [{ type: 'text', text: 'Welcome' }]
                  }
                ]
              }
            },
            headers: headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig('data', 'title')).to eq('Onboarding v2')

      get "/api/v1/team_documents/#{doc_id}", headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)['data']
      expect(body['content_text']).to include('Welcome')
    end

    it 'lists root documents when folder_id is blank' do
      TeamDocument.create!(title: 'Root doc', created_by_id: user.id, folder_id: nil)
      folder = TeamFolder.create!(name: 'Nested', created_by_id: user.id)
      TeamDocument.create!(title: 'Nested doc', created_by_id: user.id, folder_id: folder.id)

      get '/api/v1/team_documents', params: { folder_id: '' }, headers: headers
      expect(response).to have_http_status(:ok)
      titles = JSON.parse(response.body)['data'].map { |d| d['title'] }
      expect(titles).to include('Root doc')
      expect(titles).not_to include('Nested doc')
    end
  end
end
