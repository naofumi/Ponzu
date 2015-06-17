# encoding: UTF-8

# Define abilities for the passed in user here. For example:
#
#   user ||= User.new # guest user (not logged in)
#   if user.admin?
#     can :manage, :all
#   else
#     can :read, :all
#   end
#
# The first argument to `can` is the action you are giving the user permission to do.
# If you pass :manage it will apply to every action. Other common actions here are
# :read, :create, :update and :destroy.
#
# The second argument is the resource the user can perform the action on. If you pass
# :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
#
# The third argument is an optional hash of conditions to further filter the objects.
# For example, here the user can only update published articles.
#
#   can :update, Article, :published => true
#
# See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user, not saved

    # guest user
    can :read, [Presentation, User, Room, GlobalMessage]
    can [:heading, :social_box, :comments, :related], Presentation
    can [:show, :list, :like_highlights, :list_highlights, :query], [Session::Poster, Session::TimeTableable, Session::Booth, Session]
    can [:destroy], [UserSession]
    can :read, [Presentation, Session, Room]
    can [:notifications], Conference

    if !user.new_record?
      # logged in user
      can :read, [User]
      can [:view_abstract, :my, :likes, :create_comment], Presentation
      can [:destroy, :create, :reply], Comment
      can [:settings, :update_settings, :edit_name, :update_name], User
      can :edit_own_settings, User
      can [:download_pdf, :download_full_day_pdf, :download_full_pdf, :download_pdf_by_name], Session
      can [:create, :destroy, :by_day, :schedulize, :unschedulize, :my, :my_schedule], Like
      can [:create, :update, :participate], MeetUp
      can [:create, :destroy], MeetUpComment
      can [:new, :create, :threads, :conversation], PrivateMessage
      can [:delegate], Conference
    end

    if user.role? :voter
      can [:vote, :my_votes], Like
    end

    if user.role? :sponsor
      can [:update], Submission
      can [:change_ad_category], Presentation
      can :clear, Kamishibai::Cache
    end

    if user.role? :organizer
      can [:likes_report, :votes_report], Like
      can :manage, GlobalMessage
      can :clear, Kamishibai::Cache
      can [:update, :moderate, :read, :download_csv], Submission
      can [:change_ad_category, :moderate], Presentation
      can [:edit, :create, :destroy, :update], Questionnaire
      can [:create, :update, :read, :see_other], User
      
      # can :manage, User
    end

    if user.role? :previewer
      can [:preview], Conference
    end

    if user.role? :user_moderator
      can [:update, :admin_panel, 
           :admin_search, :admin_search_by_registration_id, 
           :show, :see_other], User
      # can :manage, InventoryList, :supplier_id => user.supplier_id
      # can :read, :all
    end

    if user.role? :admin
      can :manage, :all
    end
  end
end
