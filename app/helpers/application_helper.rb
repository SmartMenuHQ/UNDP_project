module ApplicationHelper
  def state_badge_class(state)
    case state.to_s
    when "draft"
      "bg-gray-100 text-gray-800"
    when "started", "in_progress"
      "bg-blue-100 text-blue-800"
    when "completed"
      "bg-green-100 text-green-800"
    when "submitted", "under_review"
      "bg-yellow-100 text-yellow-800"
    when "marked"
      "bg-green-100 text-green-800"
    when "published"
      "bg-purple-100 text-purple-800"
    when "cancelled", "expired"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def format_duration(seconds)
    return "0s" unless seconds&.positive?

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60

    if hours > 0
      "#{hours}h #{minutes}m"
    elsif minutes > 0
      "#{minutes}m #{remaining_seconds}s"
    else
      "#{remaining_seconds}s"
    end
  end

  def progress_bar_color(percentage)
    case percentage
    when 0..25
      "bg-red-500"
    when 26..50
      "bg-yellow-500"
    when 51..75
      "bg-blue-500"
    else
      "bg-green-500"
    end
  end
end
