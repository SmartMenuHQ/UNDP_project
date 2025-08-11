class Api::V1::CountriesController < Api::V1::BaseController
  skip_before_action :authenticate_with_token!
  before_action :set_country, only: [:show]

  # GET /api/v1/countries
  def index
    @countries = Country.available_for_selection
    @total_count = @countries.count

    @data = {
      countries: @countries,
      total_count: @total_count,
      regions: Country.regions,
    }

    note!("Countries retrieved successfully")
  end

  # GET /api/v1/countries/:id
  def show
    @data = {
      country: @country,
    }

    note!("Country retrieved successfully")
  end

  private

  def set_country
    @country = Country.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Country not found")
  end
end
