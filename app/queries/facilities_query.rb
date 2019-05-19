# Based on
#    https://medium.flatstack.com/query-object-in-ruby-on-rails-56ea434365f0
# Example of usage of the Query Object
# class FacilitiesController
#     def index
#         @facilities = FacilitiesSearchQuery.new(sort_query_params).all.page(params[:page])
#     end
#     private
#     def sort_query_params
#         params.slice(:sort_by, :direction)
#     end
# end
class FacilitiesQuery
    SORT_OPTIONS = %w(by_date by_title by_author).freeze
    MAIN_CATEGORIES = [ 'Shelter',
                        'Food',
                        'Medical',
                        'Hygiene',
                        'Technology',
                        'Legal',
                        'Learning' ]
    DEFAULT_COORDINATES = { 'lat': 0.0, 'long': 0.0 }

    attr_reader :main_categories, :user_coordinates

    # def initialize(relation = Facility.all, params = {}, cookies)
    def initialize(params = {}, ucookies = {})
        @cookies = ucookies
        # @relation = relation
        @params = params
        @main_categories = MAIN_CATEGORIES
        parse_coordinates
        # run
    end #/initialize

    def run
        @searched_facilities = search_by_services(service_query)
        return self
    end

    ########
    # Searches
    ##
    def opened_by_distance
        self.sort_by_distance(self.opened)
    end #/opened_by_distance

    def closed_by_distance
        self.sort_by_distance(self.closed)
    end #/closed_by_distance

    def opened_by_name
        self.opened
    end #/opened_by_name

    def closed_by_name
        self.closed
    end #/closed_by_name

    ########
    # Search Utils
    ##
    def opened
        return @opened_facilities unless @opened_facilities.nil?
        @opened_facilities = @searched_facilities.select { |fac| fac.is_open? and fac.welcomes?(self.welcome_param) }
    end #/opened
    
    def closed
        return @closed_facilities unless @closed_facilities.nil?
        @closed_facilities = @searched_facilities.select { |fac| fac.is_closed? and fac.welcomes?(self.welcome_param) }
    end #/closed
    
    def all
        # @relation.public_send(sort_by, direction)
        @searched_facilities
    end #/all

    ########
    # Attributes
    ##
    def service_query
        @params.fetch(:scope, '')
    end #/service_query

    def user_latitude
        return 0 unless @user_coordinates.include?('lat')
        @user_coordinates['lat'].to_d
    end #/user_latitude

    def user_longitude
        return 0 unless @user_coordinates.include?('long')
        @user_coordinates['long'].to_d
    end #/user_longitude

    def welcome_param
        @params.fetch(:welcome, 'All')
    end


    ########
    # Sorting
    ##
    def sort_by_distance(facilities)
        Facility.sort_by_distance(facilities, self.user_latitude, self.user_longitude)
    end #/sort_by_distance

    def list_distances(facilities)
        facilities.map{ |fac| fac.distance(self.user_latitude, self.user_longitude) }
    end #/list_distances

    private
    
        def parse_coordinates
            if @cookies.fetch(:coordinates, false)
                user_coordinates = @cookies.fetch(:coordinates)
                @user_coordinates = JSON.parse(user_coordinates)
            else
                @user_coordinates = DEFAULT_COORDINATES
            end
            # puts "UserCoord: #{user_coordinates}"
            @user_coordinates
        end #/parse_coordinates

    
        def search_by_services(service_query)
            Facility.search_by_services(service_query).is_verified.order(name: :asc)
        end #/search_by_services

        # def sort_by
        #     @params.fetch(:sort).presence_in(SORT_OPTIONS) || :by_date
        # end

        # def direction
        #     @params.fetch(:direction) == "asc" ? :asc : :desc
        # end
    

end #/FacilitiesSearchQuery