class Api::V1::Admin::CountriesController < Api::V1::Admin::BaseController
  before_action :set_country, only: [:show, :update, :destroy, :activate, :deactivate, :statistics]

  # GET /api/v1/admin/countries
  def index
    @countries = Country.all.includes(:users)
    @total_count = @countries.count

    @data = {
      countries: @countries,
      total_count: @total_count,
      active_count: Country.active.count,
      inactive_count: Country.inactive.count,
      regions: Country.regions,
    }

    note!("Countries retrieved successfully")
  end

  # GET /api/v1/admin/countries/:id
  def show
    authorize @country

    @data = {
      country: @country,
      users_count: @country.users_count,
      restricted_content_count: @country.restricted_content_count,
    }

    note!("Country retrieved successfully")
  end

  # POST /api/v1/admin/countries
  def create
    @country = Country.new(country_params)

    if @country.save
      @data = { country: @country }
      note!("Country created successfully")
    else
      raise ApiException::ValidationError.new("Country creation failed",
                                              details: { errors: @country.errors.full_messages })
    end
  end

  # PATCH/PUT /api/v1/admin/countries/:id
  def update
    authorize @country

    if @country.update(country_params)
      @data = { country: @country }
      note!("Country updated successfully")
    else
      raise ApiException::ValidationError.new("Country update failed",
                                              details: { errors: @country.errors.full_messages })
    end
  end

  # DELETE /api/v1/admin/countries/:id
  def destroy
    authorize @country

    unless @country.can_be_deleted?
      raise ApiException::ValidationError.new("Cannot delete country with associated users or content restrictions")
    end

    if @country.destroy
      @data = { deleted_id: @country.id }
      note!("Country deleted successfully")
    else
      raise ApiException::ValidationError.new("Country deletion failed",
                                              details: { errors: @country.errors.full_messages })
    end
  end

  # PATCH /api/v1/admin/countries/:id/activate
  def activate
    authorize @country, :activate?

    @country.activate!
    @data = { country: @country }
    note!("Country activated successfully")
  end

  # PATCH /api/v1/admin/countries/:id/deactivate
  def deactivate
    authorize @country, :deactivate?

    @country.deactivate!
    @data = { country: @country }
    note!("Country deactivated successfully")
  end

  # GET /api/v1/admin/countries/:id/statistics
  def statistics
    authorize @country, :view_statistics?

    @data = {
      country: @country,
      statistics: {
        users_count: @country.users_count,
        restricted_assessments_count: @country.restricted_content_count[:assessments] || 0,
        restricted_sections_count: @country.restricted_content_count[:sections],
        restricted_questions_count: @country.restricted_content_count[:questions],
        total_restricted_content: @country.restricted_content_count.values.sum,
      },
    }

    note!("Country statistics retrieved successfully")
  end

  private

  def set_country
    @country = Country.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Country not found")
  end

  def country_params
    params.require(:country).permit(:name, :code, :region, :active, :sort_order)
  end
end
