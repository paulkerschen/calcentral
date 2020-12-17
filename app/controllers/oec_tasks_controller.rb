class OecTasksController < ApplicationController
  include ClassLogger

  before_action :api_authenticate
  before_action :authorize_oec_administration

  rescue_from StandardError, with: :handle_api_exception
  rescue_from Errors::ClientError, with: :handle_client_error
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def authorize_oec_administration
    authorize current_user, :can_administer_oec?
    google_oauth_token_check
  end

  # GET /api/oec/tasks

  def index
    render json: {
      currentTerm: Berkeley::Terms.fetch.current.to_english,
      oecDepartments: Oec::ApiTaskWrapper.department_list,
      oecTasks: Oec::ApiTaskWrapper::TASK_LIST,
      oecTerms: Berkeley::Terms.fetch.campus.values.map { |term| term.to_english }
    }
  end

  # POST /api/oec/tasks/:task_name

  def run
    task_class = "Oec::Tasks::#{params['task_name']}".constantize
    params.require('term')
    task_opts = params.slice('term', 'departmentCode')
    task_status = Oec::ApiTaskWrapper.new(task_class, task_opts).start_in_background
    render json: {
      oecDriveUrl: Oec::RemoteDrive::HUMAN_URL,
      oecTaskStatus: task_status
    }
  end

  # GET /api/oec/tasks/status/:task_id

  def task_status
    task_status = Oec::Tasks::Base.fetch_from_cache params['task_id']
    raise Errors::BadRequestError, "OEC task id '#{params['task_id']}' not found" unless task_status
    render json: {
      oecTaskStatus: task_status
    }
  end

  # GET /api/oec/depts_ready_to_publish/:term_slug
  def depts_ready_to_publish
    term_code = Berkeley::TermCodes.from_slug params['term_slug']
    raise Errors::BadRequestError, "Bad term slug '#{params['term_slug']}'" unless term_code
    render json: {
      departments: Oec::ApiTaskWrapper.departments_ready_to_publish(term_code)
    }
  end

  private

  def google_oauth_token_check
    uid = Settings.oec.google.uid
    tokens = User::Oauth2Data.get(uid, GoogleApps::CredentialStore::OEC_APP_ID)
    if tokens.empty? || tokens[:access_token].blank? || tokens[:refresh_token].blank?
      raise StandardError.new "OEC features are unavailable because no Google OAuth tokens are registered with UID #{uid}. Please report this problem."
    end
  end

end
