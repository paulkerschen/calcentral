class UserController < ApplicationController
  include AllowLti

  def am_i_logged_in
    response.headers['Cache-Control'] = 'no-cache, no-store, private, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '-1'
    render :json => {
      :amILoggedIn => !!session['user_id']
    }.to_json
  end

  def my_status
    ActiveRecordHelper.clear_stale_connections
    status = {}
    features = HashConverter.camelize Settings.features.marshal_dump
    user_id = session['user_id']

    if user_id
      status.merge! User::Api.from_session(session).get_feed
    end

    status.merge!({
      canAdministerOec: current_user.policy.can_administer_oec?,
      canViewAs: current_user.policy.can_view_as?,
      features: features,
      isBasicAuthEnabled: Settings.developer_auth.enabled,
      isLoggedIn: !!user_id
    })
    render :json => status.to_json
  end

  def record_first_login
    User::Api.from_session(session).record_first_login if current_user.directly_authenticated?
    head 204
  end

end
