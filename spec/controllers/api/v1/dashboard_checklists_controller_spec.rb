# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::DashboardChecklistsController, type: :controller do
  let(:admin) { User.create!(email: 'checklist-admin@example.com', name: 'Checklist Admin') }
  let(:agent) { User.create!(email: 'checklist-agent@example.com', name: 'Checklist Agent') }

  before do
    allow(controller).to receive(:authenticate_request!).and_return(true)
  end

  after { Current.reset }

  describe 'CRUD' do
    before { Current.user = admin }

    it 'creates a checklist with items and assignees' do
      post :create, params: {
        dashboard_checklist: {
          title: 'Rotina diária',
          active: true,
          assignee_ids: [agent.id],
          items: [
            { title: 'Checar chamadas com falha', position: 0 },
            { title: 'Atualizar alertas de custo', position: 1 }
          ]
        }
      }

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body.dig('data', 'title')).to eq('Rotina diária')
      expect(body.dig('data', 'items').size).to eq(2)
      expect(body.dig('data', 'assignee_ids')).to eq([agent.id])
    end
  end

  describe 'today and toggle as assigned agent' do
    let!(:checklist) do
      DashboardChecklist.create!(
        title: 'Rotina',
        active: true,
        created_by: admin
      ).tap do |list|
        list.items.create!(title: 'Item 1', position: 0)
        list.assignments.create!(user: agent)
      end
    end

    before { Current.user = agent }

    it 'returns today items for the assigned user' do
      get :today

      expect(response).to have_http_status(:ok)
      items = response.parsed_body.dig('data', 'items')
      expect(items.size).to eq(1)
      expect(items.first['title']).to eq('Item 1')
      expect(items.first['completed']).to be(false)
    end

    it 'toggles completion for today' do
      item = checklist.items.first

      post :toggle_item, params: { item_id: item.id }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('data', 'completed')).to be(true)

      post :toggle_item, params: { item_id: item.id }
      expect(response.parsed_body.dig('data', 'completed')).to be(false)
    end
  end
end
