# frozen_string_literal: true

# == Schema Information
#
# Table name: pipeline_teams
#
#  id          :uuid             not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  pipeline_id :uuid             not null
#  team_id     :uuid             not null
#
# Indexes
#
#  index_pipeline_teams_on_pipeline_id              (pipeline_id)
#  index_pipeline_teams_on_pipeline_id_and_team_id  (pipeline_id,team_id) UNIQUE
#  index_pipeline_teams_on_team_id                  (team_id)
#
class PipelineTeam < ApplicationRecord
  belongs_to :pipeline
  belongs_to :team

  validates :team_id, uniqueness: { scope: :pipeline_id }
end
