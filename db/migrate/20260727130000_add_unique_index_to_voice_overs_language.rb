# frozen_string_literal: true

class AddUniqueIndexToVoiceOversLanguage < ActiveRecord::Migration[8.0]
  def change
    # A plain composite unique index on (tour_id, stop_id, language) would not work here:
    # Postgres treats NULL as distinct from NULL, and stop_id/tour_id is always NULL on
    # one side of the tour-or-stop split, so it would never actually block a duplicate.
    add_index(
      :voice_overs,
      [:tour_id, :language],
      unique: true,
      where: 'stop_id IS NULL',
      name: 'index_voice_overs_on_tour_and_language',
    )

    add_index(
      :voice_overs,
      [:stop_id, :language],
      unique: true,
      where: 'tour_id IS NULL',
      name: 'index_voice_overs_on_stop_and_language',
    )
  end
end
