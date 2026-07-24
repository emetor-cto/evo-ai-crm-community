# frozen_string_literal: true

class CreatePipelineTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :pipeline_teams, id: :uuid, default: -> { 'gen_random_uuid()' } do |t|
      t.references :pipeline, type: :uuid, null: false, foreign_key: true
      t.references :team, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    add_index :pipeline_teams, %i[pipeline_id team_id], unique: true,
              name: 'index_pipeline_teams_on_pipeline_id_and_team_id'
  end
end
