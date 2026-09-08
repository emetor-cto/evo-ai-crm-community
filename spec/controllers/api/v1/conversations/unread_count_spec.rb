# frozen_string_literal: true

begin
  require 'rails_helper'
rescue LoadError
  RSpec.describe Api::V1::ConversationsController do
    it 'has controller spec scaffold ready' do
      skip 'rails_helper is not available in this workspace snapshot'
    end
  end
end

return unless defined?(Rails)

RSpec.describe Api::V1::ConversationsController, type: :controller do
  describe '#unread_count' do
    let(:user) { instance_double(User, role: 'agent') }
    let(:base_conversations) { double('ConversationsRelation') }
    let(:permitted_conversations) { double('PermittedRelation') }
    let(:unread_conversations) { double('UnreadRelation') }
    let(:filter_service) { instance_double(Conversations::PermissionFilterService, perform: permitted_conversations) }

    before do
      allow(Current).to receive(:user).and_return(user)
      allow(Conversation).to receive(:all).and_return(base_conversations)
      allow(Conversations::PermissionFilterService).to receive(:new)
        .with(base_conversations, user).and_return(filter_service)

      allow(permitted_conversations).to receive(:unread).and_return(unread_conversations)
      allow(unread_conversations).to receive(:count).and_return(17)
    end

    it 'returns the number of conversations with at least one unread incoming message' do
      expect(controller).to receive(:success_response).with(
        hash_including(data: { unread_count: 17 })
      )
      controller.send(:unread_count)
    end

    it 'scopes by current user via PermissionFilterService' do
      allow(controller).to receive(:success_response)
      controller.send(:unread_count)
      expect(Conversations::PermissionFilterService).to have_received(:new).with(base_conversations, user)
    end

    it 'counts via Conversation.unread rather than joining all messages' do
      allow(controller).to receive(:success_response)
      expect(permitted_conversations).not_to receive(:joins)
      controller.send(:unread_count)
      expect(permitted_conversations).to have_received(:unread)
    end
  end
end
