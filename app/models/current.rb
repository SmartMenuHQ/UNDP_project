class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true

  def locale
    user&.default_language&.to_sym || :en
  end
end
