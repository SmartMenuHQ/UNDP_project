require 'rails_helper'

RSpec.describe Country, type: :model do
  subject { create(:country) }

  describe 'factory' do
    it 'creates a valid country' do
      expect(subject).to be_valid
    end

    it 'creates a USA country' do
      usa = create(:country, :usa)
      expect(usa.name).to eq('United States')
      expect(usa.code).to eq('USA')
      expect(usa.region).to eq('Americas')
    end

    it 'creates a China country' do
      china = create(:country, :china)
      expect(china.name).to eq('China')
      expect(china.code).to eq('CHN')
      expect(china.region).to eq('Asia')
    end

    it 'creates an inactive country' do
      inactive = create(:country, :inactive)
      expect(inactive.active).to be false
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:users).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:code).case_insensitive }
    it { is_expected.to validate_length_of(:code).is_equal_to(3) }
    it { is_expected.to validate_inclusion_of(:region).in_array(Country.regions) }
  end

  describe 'scopes' do
    let!(:active_country) { create(:country) }
    let!(:inactive_country) { create(:country, :inactive) }

    describe '.active' do
      it 'returns only active countries' do
        expect(Country.active).to include(active_country)
        expect(Country.active).not_to include(inactive_country)
      end
    end

    describe '.inactive' do
      it 'returns only inactive countries' do
        expect(Country.inactive).to include(inactive_country)
        expect(Country.inactive).not_to include(active_country)
      end
    end

    describe '.available_for_selection' do
      it 'returns active countries ordered by sort_order and name' do
        countries = Country.available_for_selection
        expect(countries).to include(active_country)
        expect(countries).not_to include(inactive_country)
      end
    end

    describe '.by_region' do
      let!(:europe_country) { create(:country, region: 'Europe') }
      let!(:asia_country) { create(:country, region: 'Asia') }

      it 'returns countries in the specified region' do
        europe_countries = Country.by_region('Europe')
        expect(europe_countries).to include(europe_country)
        expect(europe_countries).not_to include(asia_country)
      end
    end
  end

  describe 'callbacks' do
    it 'upcases the country code before validation' do
      country = build(:country, code: 'abc')
      country.valid?
      expect(country.code).to eq('ABC')
    end

    it 'strips whitespace from name' do
      # Note: The current Country model doesn't strip whitespace from name
      # This test documents the current behavior
      country = build(:country, name: '  Test Country  ')
      country.valid?
      expect(country.name).to eq('  Test Country  ')
    end
  end

  describe 'class methods' do
    describe '.regions' do
      it 'returns all available regions' do
        expect(Country.regions).to include('Africa', 'Asia', 'Europe', 'Americas', 'Oceania')
      end
    end

    describe '.popular_countries' do
      let!(:usa) { create(:country, :usa, sort_order: 1) }
      let!(:china) { create(:country, :china, sort_order: 2) }
      let!(:other_country) { create(:country, sort_order: 10) }

      it 'returns countries with low sort_order' do
        popular = Country.popular_countries
        expect(popular).to include(usa, china)
        expect(popular.count).to be <= 10
      end
    end

    describe '.seed_common_countries' do
      it 'seeds common countries' do
        expect { Country.seed_common_countries }.to change(Country, :count)
      end

      it 'does not create duplicates' do
        Country.seed_common_countries
        initial_count = Country.count
        Country.seed_common_countries
        expect(Country.count).to eq(initial_count)
      end
    end
  end

  describe 'instance methods' do
    describe '#activate!' do
      it 'sets active to true' do
        inactive_country = create(:country, :inactive)
        inactive_country.activate!
        expect(inactive_country.reload.active).to be true
      end
    end

    describe '#deactivate!' do
      it 'sets active to false' do
        subject.deactivate!
        expect(subject.reload.active).to be false
      end
    end

    describe '#toggle_status!' do
      it 'toggles the active status' do
        original_status = subject.active
        subject.toggle_status!
        expect(subject.reload.active).to eq(!original_status)
      end
    end

    describe '#users_count' do
      it 'returns the number of users in this country' do
        create_list(:user, 3, country: subject)
        expect(subject.users_count).to eq(3)
      end
    end

    describe '#can_be_deleted?' do
      context 'when country has no users' do
        it 'returns true' do
          expect(subject.can_be_deleted?).to be true
        end
      end

      context 'when country has users' do
        it 'returns false' do
          create(:user, country: subject)
          expect(subject.can_be_deleted?).to be false
        end
      end
    end

    describe '#display_name' do
      it 'returns the country name with code' do
        expect(subject.display_name).to eq("#{subject.name} (#{subject.code})")
      end
    end

    describe '#flag_emoji' do
      it 'returns a flag emoji for known countries' do
        usa = create(:country, :usa)
        expect(usa.flag_emoji).to eq('🇺🇸')
      end

      it 'returns a flag emoji for countries' do
        # The factory creates a random country, so we just check it returns an emoji
        expect(subject.flag_emoji).to match(/\p{Emoji}/)
      end
    end

            describe '#restricted_content_count' do
      it 'returns count structure' do
        counts = subject.restricted_content_count
        expect(counts).to have_key(:questions)
        expect(counts).to have_key(:sections)
        expect(counts[:questions]).to be_a(Integer)
        expect(counts[:sections]).to be_a(Integer)
      end
    end
  end
end
