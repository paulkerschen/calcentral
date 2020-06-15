module Webcast
  class Recordings

    include CalcentralConfig, ClassLogger, SafeJsonParser

    attr_accessor :fake

    def initialize(fake = false)
      @fake = fake
    end

    def get
      return {} unless Settings.features.videos

      recordings = {
        courses: {}
      }
      response = get_json_data['courses']
      # This code works for bCourses integration, but for SIS CalCentral some extra mapping was necessary to
      # support pre-CS Course Captures: https://github.com/ets-berkeley-edu/calcentral/pull/6630 and 7533
      response.each do |course|
        year = course['year']
        semester = course['semester']
        ccn = course['ccn']
        if year && semester && ccn
          key = Webcast::CourseMedia.id_per_ccn(year, semester, course['ccn'])
          recordings[:courses][key] = {
            recordings: course['recordings'],
            youtube_playlist: course['youTubePlaylist']
          }
        end
      end
      recordings
    end

    def get_json_data
      relative_path = 'course_capture/legacy_recordings.json'
      path = Rails.root.join(@fake ? 'fixtures' : local_dir, relative_path).to_s
      logger.info "Course Capture legacy JSON file: #{path} (Fake = #{@fake})"

      json_data = safe_json File.read(path)

      if json_data && (json_data.is_a? Hash)
        json_data
      else
        raise Errors::ProxyError.new('Failed to load Course Capture legacy JSON')
      end
    end
  end
end
