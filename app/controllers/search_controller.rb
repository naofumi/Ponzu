class SearchController < ApplicationController
	respond_to :html, :js
	include Kamishibai::ResponderMixin

  set_kamishibai_expiry [:index] => 1

	before_filter do |c|
	  @menu = :sessions
	  # @expiry = 60 * 60 # seconds
	end

	def index
		@query = query = params[:query]
		if params[:type] == 'presentations' && params[:page] && params[:page] != "1"
			hide_users = true
		elsif params[:type] == 'users' && params[:page] && params[:page] != "1"
			hide_presentations = true
		end
		if !query.blank?
			if !hide_presentations
				@presentations = Presentation.search do
					with(:conference_tag).equal_to(current_conference.database_tag)
					fulltext query do
						boost_fields :en_title => 2.0, :jp_title => 2.0, :keywords => 1.5
						highlight :number
						highlight :authors
						highlight :en_title
						highlight :jp_title
						highlight :en_abstract
						highlight :jp_abstract
					end
					facet	:session_id
					paginate :page => params[:page], :per_page => 20
				end
			end

			if !hide_users
				@users = Sunspot.search(Author, User) do
					with(:conference_tag).equal_to(current_conference.database_tag)
					fulltext query do
						boost_fields :en_name => 2.0, :jp_name => 2.0,
						             :authorship_en_name => 1.5, :authorship_jp_name => 1.5
					end
					paginate :page => params[:page], :per_page => 20
				end
			end
		elsif params[:flag]
			# Users can change flags during the conference
			# so we shouldn't cache in the browser for long
			@expiry = 1
			@users = Sunspot.search(User) do
				with(:conference_tag).equal_to(current_conference.database_tag)
				with :flags, params[:flag]
				with :in_categories, params[:category] if params[:category]
				paginate :page => params[:page], :per_page => 20
			end
		end
		respond_with @presentations
	end
end
