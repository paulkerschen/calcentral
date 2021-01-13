# This mailing list controller (singular) allows instructors and admins to manage a single mailing list for a single
# course site, as distinct from CanvasMailingListsController (plural), which allows admins to administer mailing lists
# across a Canvas instance.

class CanvasMailingListController < ApplicationController
  include AllowLti
  include ClassLogger
  include SpecificToCourseSite

  before_action :api_authenticate
  before_action :authorize_mailing_list_management
  rescue_from StandardError, with: :handle_api_exception
  rescue_from Errors::ClientError, with: :handle_client_error
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def authorize_mailing_list_management
    course_id = canvas_course_id
    raise Pundit::NotAuthorizedError, 'Canvas Course ID not present' if course_id.blank?
    canvas_course = Canvas::Course.new(user_id: session['user_id'], canvas_course_id: course_id)
    authorize canvas_course, :can_manage_mailing_list?
  end

  def find_mailing_list_by_id
    MailingLists::SiteMailingList.find_by canvas_site_id: canvas_course_id.to_s
  end

  # GET /api/academics/canvas/mailing_list/:canvas_course_id

  def show
    list = MailingLists::SiteMailingList.find_or_initialize_by canvas_site_id: canvas_course_id.to_s
    render json: list.to_json
  end

  # GET /api/academics/canvas/mailing_list/:canvas_course_id/welcome_email_log.csv

  def download_welcome_email_log
    unless (list = find_mailing_list_by_id)
      raise Errors::BadRequestError, "Mailing list for Canvas course ID #{canvas_course_id} not found"
    end
    respond_to do |format|
      format.csv do
        csv_filename = "#{canvas_course_id}-welcome-messages-log-#{DateTime.now.strftime('%F_%H%M%S')}.csv"
        render csv: list.members_welcomed_csv.to_s, filename: csv_filename
      end
    end
  end

  # POST /api/academics/canvas/mailing_list/:canvas_course_id/create

  def create
    list = MailingLists::MailgunList.create! canvas_site_id: canvas_course_id.to_s
    list.populate
    render json: list.to_json
  end

  # POST /api/academics/canvas/mailing_list/:canvas_course_id/welcome_email/activate

  def activate_welcome_email
    unless (list = find_mailing_list_by_id)
      raise Errors::BadRequestError, "Mailing list for Canvas course ID #{canvas_course_id} not found"
    end
    if list.welcome_email_subject.blank? || list.welcome_email_body.blank?
      raise Errors::BadRequestError, "Welcome email requires subject and body to be activated"
    end
    list.update(welcome_email_active: true)
    render json: {'welcomeEmailActive': list.welcome_email_active}
  end

  # POST /api/academics/canvas/mailing_list/:canvas_course_id/welcome_email/deactivate

  def deactivate_welcome_email
    unless (list = find_mailing_list_by_id)
      raise Errors::BadRequestError, "Mailing list for Canvas course ID #{canvas_course_id} not found"
    end
    list.update(welcome_email_active: false)
    render json: {'welcomeEmailActive': list.welcome_email_active}
  end

  # POST /api/academics/canvas/mailing_list/:canvas_course_id/welcome_email/update

  def update_welcome_email    
    unless (list = find_mailing_list_by_id)
      raise Errors::BadRequestError, "Mailing list for Canvas course ID #{canvas_course_id} not found"
    end
    raise Errors::BadRequestError, "Subject and body required" unless params['body'].present? && params['subject'].present?
    list.update(welcome_email_body: params['body'], welcome_email_subject: params['subject'])
    render json: list.to_json
  end

end
