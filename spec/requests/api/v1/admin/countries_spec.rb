require "swagger_helper"

RSpec.describe "Api::V1::Admin::Countries", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:country_china) { create(:country, :china) }
  let!(:country_inactive) { create(:country, :inactive) }

  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }

  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }

  path "/api/v1/admin/countries" do
    get "List all countries (admin)" do
      tags "Admin - Countries"
      description "Retrieve all countries including inactive ones with optional filtering (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :page, in: :query, type: :integer, required: false, description: "Page number for pagination (default: 1)", example: 1
      parameter name: :per_page, in: :query, type: :integer, required: false, description: "Items per page (default: 25, max: 100)", example: 25
      parameter name: :active, in: :query, type: :boolean, required: false, description: "Filter by active status", example: true
      parameter name: :region, in: :query, type: :string, required: false, description: "Filter by region", enum: %w[Africa Americas Asia Europe Oceania], example: "Americas"
      parameter name: :search, in: :query, type: :string, required: false, description: "Search by country name or code", example: "united"
      parameter name: :sort_by, in: :query, type: :string, required: false, description: "Sort field (name, code, sort_order)", example: "name"
      parameter name: :sort_order, in: :query, type: :string, required: false, description: "Sort direction", enum: ["asc", "desc"], example: "asc"

      response "200", "countries found" do
        let(:Authorization) { "Bearer #{admin_token}" }

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
                     active_count: { type: :integer },
                     inactive_count: { type: :integer },
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
          expect(data["data"]["active_count"]).to be_a(Integer)
          expect(data["data"]["inactive_count"]).to be_a(Integer)
          expect(data["data"]["regions"]).to be_an(Array)
          expect(data["notes"]).to include("Countries retrieved successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "401", "unauthorized - no token" do
        let(:Authorization) { nil }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end

    post "Create a new country (admin)" do
      tags "Admin - Countries"
      description "Create a new country (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :country, in: :body, description: "Country data for creation", schema: {
        type: :object,
        properties: {
          country: {
            type: :object,
            description: "Country attributes",
            properties: {
              name: {
                type: :string,
                description: "Country name (must be unique)",
                example: "New Country",
                maxLength: 100,
              },
              code: {
                type: :string,
                description: "ISO 3166-1 alpha-3 country code (must be unique, 3 uppercase letters)",
                example: "NEW",
                pattern: "^[A-Z]{3}$",
                minLength: 3,
                maxLength: 3,
              },
              region: {
                type: :string,
                description: "Geographic region",
                enum: %w[Africa Americas Asia Europe Oceania],
                example: "Americas",
              },
              active: {
                type: :boolean,
                description: "Whether the country should be active and available for selection",
                example: true,
              },
              sort_order: {
                type: :integer,
                description: "Display order (lower numbers appear first)",
                example: 0,
                minimum: 0,
              },
            },
            required: %w[name code region],
          },
        },
        required: ["country"],
        example: {
          country: {
            name: "New Country",
            code: "NEW",
            region: "Americas",
            active: true,
            sort_order: 0,
          },
        },
      }

      response "200", "country created" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     country: { "$ref" => "#/components/schemas/Country" },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Country created successfully"] },
               },
               examples: {
                 country_created: {
                   summary: "New country created successfully",
                   value: {
                     status: "ok",
                     data: {
                       country: {
                         id: 1,
                         name: "United States",
                         code: "USA",
                         region: "Americas",
                         active: true,
                         users_count: 0,
                         created_at: "2024-01-01T00:00:00.000Z",
                       },
                     },
                     errors: [],
                     notes: ["Country created successfully"],
                   },
                 },
               }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:country) do
          {
            country: {
              name: "New Country",
              code: "NEW",
              region: "Americas",
              active: true,
              sort_order: 0,
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["country"]["name"]).to eq("New Country")
          expect(data["data"]["country"]["code"]).to eq("NEW")
          expect(data["notes"]).to include("Country created successfully")
        end
      end

      response "422", "validation failed" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:country) do
          {
            country: {
              name: "",
              code: "",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:country) do
          {
            country: {
              name: "New Country",
              code: "NEW",
              region: "Americas",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/countries/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Country ID"

    get "Get country details (admin)" do
      tags "Admin - Countries"
      description "Retrieve details of a specific country with statistics (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "country found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { country_usa.id }

        schema type: :object,
               properties: {
                 status: { type: :string, enum: ["ok", "error", "redirect"] },
                 data: {
                   type: :object,
                   properties: {
                     country: { "$ref" => "#/components/schemas/Country" },
                     users_count: { type: :integer },
                     restricted_content_count: {
                       type: :object,
                       properties: {
                         questions: { type: :integer },
                         sections: { type: :integer },
                       },
                     },
                   },
                 },
                 errors: { type: :array, items: { type: :string } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["country"]["id"]).to eq(country_usa.id)
          expect(data["data"]["users_count"]).to be_a(Integer)
          expect(data["data"]["restricted_content_count"]).to be_a(Hash)
          expect(data["notes"]).to include("Country retrieved successfully")
        end
      end

      response "404", "country not found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { country_usa.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end

    patch "Update country (admin)" do
      tags "Admin - Countries"
      description "Update a country (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :country, in: :body, schema: {
        type: :object,
        properties: {
          country: {
            type: :object,
            properties: {
              name: { type: :string },
              code: { type: :string },
              region: { type: :string },
              active: { type: :boolean },
              sort_order: { type: :integer },
            },
          },
        },
        required: ["country"],
      }

      response "200", "country updated" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { country_usa.id }
        let(:country) do
          {
            country: {
              name: "Updated States",
              region: "Americas",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["country"]["name"]).to eq("Updated States")
          expect(data["notes"]).to include("Country updated successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { country_usa.id }
        let(:country) do
          {
            country: {
              name: "Updated States",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end

    delete "Delete country (admin)" do
      tags "Admin - Countries"
      description "Delete a country (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "country deleted" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let!(:country_to_delete) { create(:country, name: "Delete Me", code: "DEL", region: "Americas") }
        let(:id) { country_to_delete.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["deleted_id"]).to eq(country_to_delete.id)
          expect(data["notes"]).to include("Country deleted successfully")
        end
      end

      response "403", "cannot delete country with users" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { country_usa.id } # Has users associated

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_failed")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { country_china.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/countries/{id}/activate" do
    parameter name: :id, in: :path, type: :integer, description: "Country ID"

    patch "Activate country (admin)" do
      tags "Admin - Countries"
      description "Activate a country (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "country activated" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { country_inactive.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["country"]["active"]).to be true
          expect(data["notes"]).to include("Country activated successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { country_inactive.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/countries/{id}/deactivate" do
    parameter name: :id, in: :path, type: :integer, description: "Country ID"

    patch "Deactivate country (admin)" do
      tags "Admin - Countries"
      description "Deactivate a country (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "country deactivated" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { country_china.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["country"]["active"]).to be false
          expect(data["notes"]).to include("Country deactivated successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { country_china.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/countries/{id}/statistics" do
    parameter name: :id, in: :path, type: :integer, description: "Country ID"

    get "Get country statistics (admin)" do
      tags "Admin - Countries"
      description "Get detailed statistics for a country (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "statistics retrieved" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { country_usa.id }

        schema type: :object,
               properties: {
                 status: { type: :string, enum: ["ok", "error", "redirect"] },
                 data: {
                   type: :object,
                   properties: {
                     country: { "$ref" => "#/components/schemas/Country" },
                     statistics: {
                       type: :object,
                       properties: {
                         users_count: { type: :integer },
                         restricted_assessments_count: { type: :integer },
                         restricted_sections_count: { type: :integer },
                         restricted_questions_count: { type: :integer },
                         total_restricted_content: { type: :integer },
                       },
                     },
                   },
                 },
                 errors: { type: :array, items: { type: :string } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["country"]["id"]).to eq(country_usa.id)
          expect(data["data"]["statistics"]["users_count"]).to be_a(Integer)
          expect(data["data"]["statistics"]["total_restricted_content"]).to be_a(Integer)
          expect(data["notes"]).to include("Country statistics retrieved successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { country_usa.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end
end
