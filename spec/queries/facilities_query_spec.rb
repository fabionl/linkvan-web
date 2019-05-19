require 'rails_helper'

# Supporting tools
def coordinates(fac)
    lat = cookies[:coordinates]['lat']
    long = cookies[:coordinates]['long']
    return "#{fac.name}(#{fac.id}):[#{fac.lat}, #{fac.long}, #{fac.distance(lat, long)}]"
end
def user_coordinates(fac_query)
    lat = fac_query.user_latitude
    long = fac_query.user_longitude
    return "[#{lat}, #{long}]"
end
def print_closed(fac_query)
    fac_query.closed.each { |fac| puts ("#{coordinates(fac)}") } 
end
def print_closed_distance(fac_query)
    fac_query.closed_by_distance.each { |fac| puts ("#{coordinates(fac)}") } 
end
def new_cookies_obj
    cook_obj = { coordinates: JSON.generate( coord_hash ) }
    cook_obj
end
def coord_hash
    { 'lat': 49.2, 'long': -123.0 }
end

RSpec.describe FacilitiesQuery do
    # These are the main categories we use. It's hardcoded in the class to keep fine control of them.
    let(:main_categories) { ['Shelter', 'Food', 'Medical', 'Hygiene', 'Technology', 'Legal', 'Learning'] }
    
    let(:cookies) { new_cookies_obj }
    let(:params)  { {scope: 'Legal'} }

    let(:subject) { FacilitiesQuery.new }

    describe 'Coordinates' do

        context 'user_latitude' do
            it 'should return 0 if latitude not present in cookies' do
                expect(subject.user_latitude).to eq(0)
            end
            it "should return 'lat' value from cookies" do
                fac_query = FacilitiesQuery.new( params, cookies )
                user_lat = coord_hash.fetch(:lat)
                expect(fac_query.user_latitude).to eq(user_lat)
            end
            
        end
        context 'user_longitude' do
            it 'should return 0 if longitude not present in cookies' do
                expect(subject.user_longitude).to eq(0)
            end
            it "should return 'long' value from cookies" do
                fac_query = FacilitiesQuery.new( params, cookies )
                user_long = coord_hash.fetch(:long)
                expect(fac_query.user_longitude).to eq(user_long)
            end
        
        end
    end #/Coordinates

    context 'searches' do
        fixtures :facilities

        let(:open_all_day) { facilities(:open_all_day) }
        let(:open_all_day_nearby) { facilities(:open_all_day_nearby) }
        let(:close_all_day) { facilities(:close_all_day) }
        let(:close_all_day_nearby) { facilities(:close_all_day_nearby) }
        let(:open_by_name) { [open_all_day, open_all_day_nearby] }
        let(:close_by_name) { [close_all_day, close_all_day_nearby] }
        let(:open_by_distance) { [open_all_day_nearby, open_all_day] }
        let(:close_by_distance) { [close_all_day_nearby, close_all_day] }

        let(:facilities_query) { FacilitiesQuery.new(params, cookies).run }
        
        describe '#opened_by_distance' do
            it 'should return opened facilities sorted by distance' do
                expect(facilities_query.opened_by_distance).to eq(open_by_distance)
            end
        end #/opened_by_distance
        describe '#closed_by_distance' do
            it 'should return closed facilities sorted by distance' do
                # print_closed_distance(facilities_query)
                expect(facilities_query.closed_by_distance).to eq(close_by_distance)
            end
        end #/closed_by_distance
        describe '#opened_by_name' do
            it 'should return opened facilities sorted by name' do
                expect(facilities_query.opened_by_name).to eq(open_by_name)
            end
        end #/opened_by_name
        describe '#closed_by_name' do
            it 'should return closed facilities sorted by name' do
                expect(facilities_query.closed_by_name).to eq(close_by_name)
            end
        end #/closed_by_name
    end #/searches performed

    describe 'Main Categories' do

        it 'should contain a list of main categories in the right order' do
            expect(subject.main_categories).to eq(main_categories)
        end

    end #/Main Categories

end #/FacilitiesQuery