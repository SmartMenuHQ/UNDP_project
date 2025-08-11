json.partial! "/api/v1/base"

if @data[:section]
  json.data do
    json.section do
      json.partial! "api/v1/shared/assessment_section", section: @data[:section]
    end

    json.questions_count @data[:questions_count]

    if @data[:assessment]
      json.assessment @data[:assessment]
    end

    if @data[:statistics]
      json.statistics @data[:statistics]
    end
  end
end
