# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Contacts::ConversationsController, type: :controller do
  describe '#index' do
    let(:contact) { instance_double(Contact, id: 'contact-1') }
    let(:user) { instance_double(User, role: 'administrator') }
    let(:scope) { double('ConversationsScope') }
    let(:ordered) { double('OrderedConversations') }
    let(:limited) { [instance_double(Conversation, id: 'conv-1')] }
    let(:serialized) { [{ 'id' => 'conv-1', 'uuid' => 'uuid-1' }] }

    before do
      allow(controller).to receive(:authenticate_request!)
      allow(Contact).to receive(:find).with('contact-1').and_return(contact)
      allow(Current).to receive(:user).and_return(user)
      allow(Conversation).to receive(:includes).and_return(scope)
      allow(scope).to receive(:where).with(contact_id: 'contact-1').and_return(scope)
      allow(Conversations::PermissionFilterService).to receive(:new)
        .with(scope, user, nil).and_return(instance_double(Conversations::PermissionFilterService, perform: scope))
      allow(scope).to receive(:order).with(last_activity_at: :desc).and_return(ordered)
      allow(ordered).to receive(:limit).with(20).and_return(limited)
      allow(ConversationSerializer).to receive(:serialize_collection)
        .with(limited, include_messages: false, include_labels: true)
        .and_return(serialized)
    end

    it 'returns conversations in the standard success envelope' do
      expect(controller).to receive(:success_response).with(
        hash_including(data: serialized)
      )

      controller.params = ActionController::Parameters.new(contact_id: 'contact-1')
      controller.send(:ensure_contact)
      controller.index
    end
  end
end
