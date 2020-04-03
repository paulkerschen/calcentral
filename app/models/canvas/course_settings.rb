module Canvas
  class CourseSettings < Proxy
    include ClassLogger

    DEFAULT_HOME_PAGE = 'feed'

    def initialize(options = {})
      super(options)
      @course_id = options[:course_id]
    end

    def settings(options = {})
      optional_cache(options, key: @course_id.to_s, default: true) do
        wrapped_get "#{request_path}/settings"
      end
    end

    def hide_grade_distributions()
      logger.info "Will hide grade distributions for site ID #{@course_id}"
      results = wrapped_put "#{request_path}/settings", {
        'hide_distribution_graphs' => true
      }
      logger.error "Could not hide grade distributions for site ID #{@course_id}" if results[:statusCode] != 200
      results
    end

    # WARNING: This is currently undocumented. Described at "https://community.canvaslms.com/thread/11645".
    def set_default_view(default_view)
      wrapped_put request_path, {
        'course' => {
          'default_view' => default_view
        }
      }
    end

    # If necessary, reset a site to use ETS's preferred default landing page.
    def fix_default_view(course_properties)
      if course_properties['default_view'] != DEFAULT_HOME_PAGE
        logger.info "Will change default view for site ID #{@course_id} from '#{course_properties['default_view']}' to '#{DEFAULT_HOME_PAGE}'"
        results = set_default_view DEFAULT_HOME_PAGE
        logger.error "Could not change default view for site ID #{@course_id}" if results[:statusCode] != 200
        results
      end
    end

    private

    def request_path
      "courses/#{@course_id}"
    end

    def mock_interactions
      on_request(uri_matching: "#{api_root}/#{request_path}", method: :get)
        .respond_with_file('fixtures', 'json', 'canvas_course_settings.json')

      on_request(uri_matching: "#{api_root}/#{request_path}/settings", method: :put)
        .respond_with_file('fixtures', 'json', 'canvas_course_settings_hide_grade_distributions.json')
    end

  end
end
