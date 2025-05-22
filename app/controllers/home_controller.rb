require 'httparty'
require 'json'
require 'time'

class HomeController < ApplicationController
  BIRDS_BY_NAME =
    JSON
      .parse(File.read(Rails.root.join('public', 'birds.json')))
      .index_by { |b| b['name'].downcase }   # → { "mallard" => {…}, … }

  def index
    response   = HTTParty.get('https://jbird.james.baby/api/sightings')
    @sightings = JSON.parse(response.body)

    @chart_data      = @sightings.map { |s| Time.parse(s['timestamp']).to_date }
    @species_by_day  = @sightings.group_by { |s| Date.parse(s['timestamp']) }
                                 .transform_values { |ss| ss.group_by { |s| s['species'] }
                                                            .transform_values(&:count) }

    @species_past_day =
      @sightings
        .select { |s| Time.parse(s['timestamp']) > 1.day.ago }
        .group_by { |s| s['species'] }
        .transform_values(&:count)

    @species_past_day_top = @species_past_day.max_by(3, &:last).to_h
    @species_past_day_min = @species_past_day.min_by(5, &:last).to_h

    @sightings.each do |s|
      if (info = BIRDS_BY_NAME[s['species'].downcase])
        s['bird_info'] = info
      end
    end

    @bird_info_by_species = @species_past_day.keys.to_h do |name|
      [name, BIRDS_BY_NAME[name.downcase]] if BIRDS_BY_NAME.key?(name.downcase)
    end.compact
  end
end
