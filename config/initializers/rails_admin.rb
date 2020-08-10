# RailsAdmin config file.
# See github.com/sferik/rails_admin for more information.

RailsAdmin.config do |config|

  ################  Global configuration  ################

  # Set the admin name here (optional second array element will appear in red). For example:
  config.main_app_name = ['CalCentral', 'Admin']
  # or for a more dynamic name:
  # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }

  # We're not using Devise or Warden for RailsAdmin authentication; check for superuser in authenticate_with instead.
  config.authenticate_with {
    if cookies[:reauthenticated] || !!Settings.features.reauthentication == false
      policy = AuthenticationState.new(session).policy
      redirect_to main_app.root_path unless policy.can_administrate?
    else
      redirect_to main_app.reauth_admin_path
    end
  }

  # If you want to track changes on your models:
  # config.audit_with :history, 'Adminuser'

  # Or with a PaperTrail: (you need to install it first)
  # config.audit_with :paper_trail, 'User'

  # Display empty fields in show views:
  # config.compact_show_view = false

  # Number of default rows per-page:
  config.default_items_per_page = 50

  # Exclude specific models (keep the others):
  # config.excluded_models = ['OracleDatabase']

  # Include specific models (exclude the others):
  config.included_models = %w(
    CanvasCsv::Synchronization
    MailingLists::Member MailingLists::SiteMailingList
    Oec::CourseCode
    User::Auth
  )

  # Label methods for model instances:
  # config.label_methods << :description # Default is [:name, :title]

  # config.model This::That do
  # end

  ################  Model configuration  ################

  # Each model configuration can alternatively:
  #   - stay here in a `config.model 'ModelName' do ... end` block
  #   - go in the model definition file in a `rails_admin do ... end` block

  # This is your choice to make:
  #   - This initializer is loaded once at startup (modifications will show up when restarting the application) but all RailsAdmin configuration would stay in one place.
  #   - Models are reloaded at each request in development mode (when modified), which may smooth your RailsAdmin development workflow.
  #

  config.model 'CanvasCsv::Synchronization' do
    label 'Sync Timestamps'
  end

  config.model 'MailingLists::Member' do
    label 'Mailing List Memberships'
  end

  config.model 'MailingLists::SiteMailingList' do
    label 'Mailing Lists'
  end

  config.model 'User::Auth' do
    label 'User Authorizations'
    list do
      field :uid do
        column_width 60
      end
      field :is_superuser do
        column_width 20
      end
      field :is_viewer do
        column_width 20
      end
      field :is_canvas_whitelisted do
        column_width 20
      end
      field :active do
        column_width 20
      end
      field :created_at do
        column_width 130
      end
      field :updated_at do
        column_width 130
      end
    end
  end

  config.navigation_static_label = 'Tools'

  config.navigation_static_links = {
  }

end
