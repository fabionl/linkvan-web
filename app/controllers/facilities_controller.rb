require 'securerandom'

class FacilitiesController < ApplicationController
  before_action :require_signin, only: [:edit, :update, :new, :create, :destroy]
  #use impressionist to log views to display on user show page
  include FacilitiesHelper
  def index
    @facilities = Facility.all
    @alert = Alert.where(active: true).first
    @notices = Notice.where(published: true)

    respond_to do |format|
      format.html
      format.csv { send_data @facilities.to_csv, filename: "facilities-#{Date.today}.csv" }
    end
  end


    def filtered
      add_breadcrumb params[:scope]
      session['facilities_category'] = params[:scope]
      session['facilities_list'] = request.original_url

      # fq = FacilitiesQuery.new(params, cookies)
      # logger.info fq.user_coordinates
      ######
      # Debugging discoveries: (Fabio: 2019-05-19)
      ## case params[:scope] when Search
      # is never reached. I could not reproduce its usage.
      ## params[:welcome] is never set
      # logger.info "welcome param: #{params[:welcome]}"
      ## params[:sortby] is never set
      # logger.info "sortby param: #{params[:sortby]}"
      ## params[:hours] is never set
      # logger.info "hours param: #{params[:hours]}"
      ## params[:services] is never set
      # logger.info "services param: #{params[:services]}"
      
      @scope = params[:scope]

      fac_query = FacilitiesQuery.new(params, cookies)
      @latitude = fac_query.user_latitude
      @longitude = fac_query.user_longitude

      # These facilities_*_* variables are not needed anymore with the
      #    implementation of the query object. I'm keeping them for now
      #    because the views will need to be refactored.
      # TODO: Refactor Views and simply FacilitiesController#filtered
      search_cat = fac_query.main_categories.select{ |cat| cat == @scope }
      unless search_cat.empty?
        fac_query.run
        @facilities_near_yes = fac_query.opened_by_distance
        @facilities_near_no = fac_query.closed_by_distance
        @facilities_name_yes = fac_query.opened_by_name
        @facilities_name_no = fac_query.closed_by_name
      else
        @facilities_near_yes = Facility.is_verified
        @facilities_near_no = Facility.is_verified
        @facilities_name_yes = Facility.is_verified
        @facilities_name_no = Facility.is_verified
      end

      @facilities_near_yes_distance = fac_query.list_distances(@facilities_near_yes)
      @facilities_near_no_distance = fac_query.list_distances(@facilities_near_no)
      @facilities_name_yes_distance = fac_query.list_distances(@facilities_name_yes)
      @facilities_name_no_distance = fac_query.list_distances(@facilities_name_no)


      if !cookies[:non_data_user].present?
        if !session[:id].present?
          session[:id] = SecureRandom.uuid
        end
        if !cookies[:userid].present?
          cookies[:userid] = SecureRandom.uuid
        end

        @analytic = Analytic.new do |a|
          a.sessionID = session[:id]
          a.time = Time.new
          a.cookieID = cookies[:userid]
          a.service = params[:scope]
          a.lat = @latitude
          a.long = @longitude
        end

        if @analytic.save
          session[:current_data] = @analytic.id
          puts "Test"
          @facilities_near_yes.each_with_index do |f, i|
            @option = ListedOption.new do |o|
              o.analytic_id = @analytic.id
              o.sessionID = session[:id]
              o.time = @analytic.time
              o.facility = f.name
              o.position = i + 1
              o.total = @facilities_near_yes.length
            end
            @option.save
          end
        end
      end

      if !session[:current_data].present?
        session[:current_data] = -1
      end

    end

  def directions
    @facility = Facility.find(params[:id])
    if session[:current_data].present?
      @analytic = Analytic.find(session[:current_data])
      @analytic.dirClicked = true
      @analytic.dirType = "Walking"
      @analytic.save
    end
  end

  def options
  end

  def search

    if isKeyword(params[:search])
      @facilities = Facility.keywordSearch( getKeyword(params[:search]) )
    else
      @facilities = Facility.search(params[:search]).is_verified

    end
    @facilities.is_verified
  end #/search



	def show
		@facility = Facility.find(params[:id])

    if session['facilities_category']
      add_breadcrumb session['facilities_category'], session['facilities_list']
    end
    add_breadcrumb @facility.name
    
    if session[:current_data].present?
      @analytic = Analytic.find(session[:current_data])
      @analytic.facility = @facility.id
      @analytic.save
    else
      puts 'ERROR DATA NOT FOUND'
    end

    #impressionist(@facility, @facility.name)
	end

  def toggle_verify
    @current_user = User.find(session[:user_id])
    @facility = Facility.find(params[:id])
    if @facility.verified == true
      @facility.update_attribute(:verified, false)
    else
      @facility.update_attribute(:verified, true)
    end
    @facility.save
    render json: {verified: @facility.verified}
  end

	def edit
		@facility = Facility.find(params[:id])
	end

	def update
		@facility = Facility.find(params[:id])
		if @facility.update(facility_params)
      Status.create(fid: @facility.id, changetype: "U")
		  redirect_to @facility
    else
      render :edit
    end
	end

	def new
		@facility = Facility.new
	end

	def create
		@facility = Facility.new(facility_params)
    @facility.user_id = current_user.id
		if @facility.save
      Status.create(fid: @facility.id, changetype: "C")
		  redirect_to @facility
    else
      render :new
    end
	end

	def destroy
		@facility = Facility.find(params[:id])
    Status.create(fid: @facility.id, changetype: "D")
		@facility.destroy
		redirect_to facilities_url
	end


private

	def facility_params
		params.require(:facility).
							permit(:name, :welcomes, :services, :address, :phone, :user_id, :verified,
								:website, :description, :startsmon_at, :endsmon_at, :startstues_at, :endstues_at,
                  :startswed_at, :endswed_at, :startsthurs_at, :endsthurs_at, :startsfri_at, :endsfri_at,
                    :startssat_at, :endssat_at, :startssun_at, :endssun_at, :notes, :lat, :long,
                       :startsmon_at2, :endsmon_at2, :startstues_at2, :endstues_at2, :startswed_at2, :endswed_at2,
                          :startsthurs_at2, :endsthurs_at2, :startsfri_at2, :endsfri_at2, :startssat_at2, :endssat_at2,
                             :startssun_at2, :endssun_at2, :open_all_day_mon, :open_all_day_tues, :open_all_day_wed, :open_all_day_thurs,
                                :open_all_day_fri, :open_all_day_sat, :open_all_day_sun, :closed_all_day_mon, :closed_all_day_tues, :closed_all_day_wed,
                                   :closed_all_day_thurs, :closed_all_day_fri, :closed_all_day_sat, :closed_all_day_sun, :r_pets, :r_id, :r_cart, :r_phone, :r_wifi,
                                      :second_time_mon, :second_time_tues, :second_time_wed, :second_time_thurs, :second_time_fri, :second_time_sat, :second_time_sun,
                                      :shelter_note, :food_note, :medical_note, :hygiene_note, :technology_note, :legal_note, :learning_note )
	end #/facility_params

  def getKeyword(word)
		@word = word
		@word = @word.strip
		@word = @word.downcase
		case @word
		when "children", "child"
			return @word = "children"
		when "youth", "youths"
			return @word = "youth"
		when "adult", "adults"
			return @word = "adult"
		when "senior", "seniors"
			return @word = "senior"
		when "shelter", "house", "housing"
			return @word = "Shelter"
		when "food"
			return @word = "Food"
		when "medical"
			return @word = "Medical"
		when "hygiene", "clean", "cleaning", "shower"
			return @word = "Hygiene"
		when "technology", "computer", "tech"
			return @word = "Technology"
		when "legal", "law"
			return @word = "Legal"
		when "learning", "learn", "education", "teaching", "teach", "teacher"
			return @word = "Learning"
		when "suitability", "all", "facilities", "facility"
			return @word = "all"
		else
			return @word
		end
	end #/getKeyword

  def isKeyword(search)
    @word = params[:search]
    @word = @word.strip
    @word = @word.downcase
    case @word
    when "child", "children", "youth", "youths", "adult", "adults", "senior", "seniors", "suitability", "shelter", "house", "housing", "food", "medical", "hygiene", "clean", "cleaning", "shower", "technology", "computer", "tech", "legal", "law", "learning", "learn", "education", "teaching", "teach", "teacher", "all", "facility", "facilities"
      return true
    else
      return false
    end
  end #/isKeyword

end #/FacilitiesController

