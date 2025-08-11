require "swagger_helper"

RSpec.describe "Api::V1::Countries", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:country_china) { create(:country, :china) }
  let!(:country_inactive) { create(:country, :inactive) }

  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }

  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }

  path "/api/v1/countries" do
    get "List all active countries" do
      tags "Countries"
      description "Retrieve all active countries available for selection with optional filtering"
      produces "application/json"

      parameter name: :region, in: :query, type: :string, required: false, description: "Filter by geographic region", enum: %w[Africa Americas Asia Europe Oceania], example: "Americas"
      parameter name: :search, in: :query, type: :string, required: false, description: "Search by country name", example: "united"
      parameter name: :sort_by, in: :query, type: :string, required: false, description: "Sort field (name, sort_order)", example: "name"
      parameter name: :sort_order, in: :query, type: :string, required: false, description: "Sort direction", enum: ["asc", "desc"], example: "asc"

      response "200", "countries found" do
        schema type: :object,
               properties: {
                 status: { type: :string, enum: ["ok", "error", "redirect"] },
                 data: {
                   type: :object,
                   properties: {
                     countries: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/Country" },
                     },
                     total_count: { type: :integer },
                     regions: {
                       type: :array,
                       items: { type: :string },
                     },
                   },
                 },
                 errors: { type: :array, items: { type: :string } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["countries"]).to be_an(Array)
          expect(data["data"]["total_count"]).to be_a(Integer)
          expect(data["data"]["regions"]).to be_an(Array)
          expect(data["notes"]).to include("Countries retrieved successfully")

          # Should only return active countries
          countries = data["data"]["countries"]
          expect(countries.all? { |c| c["active"] == true }).to be true
        end
      end
    end
  end

  path "/api/v1/countries/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Country ID"

    get "Get country details" do
      tags "Countries"
      description "Retrieve details of a specific country"
      produces "application/json"

      response "200", "country found" do
        schema type: :object,
               properties: {
                 status: { type: :string, enum: ["ok", "error", "redirect"] },
                 data: {
                   type: :object,
                   properties: {
                     country: { "$ref" => "#/components/schemas/Country" },
                   },
                 },
                 errors: { type: :array, items: { type: :string } },
                 notes: { type: :array, items: { type: :string } },
               }

        let(:id) { country_usa.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["country"]["id"]).to eq(country_usa.id)
          expect(data["data"]["country"]["name"]).to eq(country_usa.name)
          expect(data["notes"]).to include("Country retrieved successfully")
        end
      end

      response "404", "country not found" do
        let(:id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end
    end
  end
end
