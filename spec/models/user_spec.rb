# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  default_language       :string           default("en")
#  email_address          :string           not null
#  first_name             :string
#  invitation_accepted_at :datetime
#  invited_at             :datetime
#  last_name              :string
#  password_digest        :string           not null
#  profile_completed      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  country_id             :bigint
#  invited_by_id          :bigint
#
# Indexes
#
#  index_users_on_admin              (admin)
#  index_users_on_country_id         (country_id)
#  index_users_on_default_language   (default_language)
#  index_users_on_email_address      (email_address) UNIQUE
#  index_users_on_invited_by_id      (invited_by_id)
#  index_users_on_profile_completed  (profile_completed)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (invited_by_id => users.id)
#
require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    it "creates a valid user" do
      user = create(:user)
      expect(user).to be_valid
      expect(user.email_address).to be_present
      expect(user.first_name).to be_present
      expect(user.last_name).to be_present
    end

    it "creates an admin user" do
      admin = create(:user, :admin)
      expect(admin).to be_admin
    end

    it "creates a Chinese user" do
      chinese_user = create(:user, :chinese)
      expect(chinese_user.country.code).to eq("CHN")
      expect(chinese_user.default_language).to eq("en")
    end
  end

  describe "associations" do
    it { should belong_to(:country).optional }
    it { should have_many(:assessment_response_sessions).dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:user) }

    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address).ignoring_case_sensitivity }
  end

  describe "methods" do
    let(:user) { create(:user, first_name: "John", last_name: "Doe") }

    it "returns full name" do
      expect(user.full_name).to eq("John Doe")
    end

    it "returns display name" do
      expect(user.display_name).to eq("John Doe")
    end
  end
end
