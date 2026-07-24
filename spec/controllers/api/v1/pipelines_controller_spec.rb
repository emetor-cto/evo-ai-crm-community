# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::PipelinesController, type: :controller do
  let(:user) { User.create!(email: 'pipeline-teams-spec@example.com', name: 'Spec User') }
  let(:team) { Team.create!(name: "Vendas #{SecureRandom.hex(3)}") }
  let(:pipeline) do
    Pipeline.create!(
      name: "Pipeline #{SecureRandom.hex(3)}",
      pipeline_type: 'sales',
      visibility: :private,
      created_by: user
    )
  end

  before do
    Current.user = user
    Current.service_authenticated = true
    Current.authentication_method = 'service_token'

    allow(controller).to receive(:authenticate_request!).and_return(true)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:validate_pipeline_limit).and_return(true)
    allow(controller).to receive(:pundit_user).and_return({ user: user, account_user: nil })
  end

  after { Current.reset }

  describe 'PATCH #update with team visibility' do
    it 'persists selected team_ids when visibility is team' do
      patch :update, params: {
        id: pipeline.id,
        pipeline: {
          visibility: 'team',
          team_ids: [team.id]
        }
      }

      expect(response).to have_http_status(:ok)
      pipeline.reload
      expect(pipeline.visibility).to eq('team')
      expect(pipeline.team_ids).to contain_exactly(team.id)

      body = JSON.parse(response.body)
      expect(body.dig('data', 'team_ids')).to contain_exactly(team.id)
    end

    it 'rejects team visibility without teams' do
      patch :update, params: {
        id: pipeline.id,
        pipeline: {
          visibility: 'team',
          team_ids: []
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(pipeline.reload.visibility).not_to eq('team')
      expect(pipeline.team_ids).to be_empty
    end

    it 'rejects switching to team visibility when team_ids is omitted (Rails drops empty arrays)' do
      patch :update, params: {
        id: pipeline.id,
        pipeline: {
          visibility: 'team'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(pipeline.reload.visibility).not_to eq('team')
    end

    it 'clears team associations when switching away from team visibility' do
      pipeline.update!(visibility: :team)
      pipeline.teams << team

      patch :update, params: {
        id: pipeline.id,
        pipeline: {
          visibility: 'private',
          team_ids: []
        }
      }

      expect(response).to have_http_status(:ok)
      expect(pipeline.reload.visibility).to eq('private')
      expect(pipeline.team_ids).to be_empty
    end
  end

  describe 'POST #create with team visibility' do
    it 'creates pipeline with team associations' do
      post :create, params: {
        pipeline: {
          name: "Team Pipeline #{SecureRandom.hex(3)}",
          pipeline_type: 'sales',
          visibility: 'team',
          team_ids: [team.id]
        },
        create_default_stages: false
      }

      expect(response).to have_http_status(:created)
      created = Pipeline.find(JSON.parse(response.body).dig('data', 'id'))
      expect(created.visibility).to eq('team')
      expect(created.team_ids).to contain_exactly(team.id)
    end
  end
end
