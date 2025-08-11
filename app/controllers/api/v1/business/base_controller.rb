class Api::V1::Business::BaseController < Api::V1::BaseController
  before_action :authenticate_user!
end
