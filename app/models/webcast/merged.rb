module Webcast
  class Merged < UserSpecificModel
    include Cache::CachedFeed

    def initialize(uid, course_policy, term_yr, term_cd, ccn_list, options = {})
      super(uid.nil? ? nil : uid.to_i, options)
      @term_yr = term_yr.to_i unless term_yr.nil?
      @term_cd = term_cd
      @ccn_list = ccn_list
      @options = options
      @course_policy = course_policy
    end

    def get_feed_internal
      logger.warn "Webcast merged feed where year=#{@term_yr}, term=#{@term_cd}, ccn_list=#{@ccn_list.to_s}, course_policy=#{@course_policy.to_s}"
      @academics = Berkeley::Teaching.new(@uid)
      get_media_feed
    end

    private

    def get_media_feed
      media = get_media
      feed = {}
      if media.any?
        media_hash = {
          :media => media,
          :videos => merge(media, :videos)
        }
        feed.merge! media_hash
      end
      feed
    end

    def get_media
      feed = []
      if @term_yr && @term_cd
        media_per_ccn = Webcast::CourseMedia.new(@term_yr, @term_cd, @ccn_list, @options).get_feed
        if media_per_ccn.any?
          ccn_list = media_per_ccn.keys
          if Berkeley::TermCodes.legacy?(@term_yr, @term_cd)
            legacy_sections = Berkeley::LegacyTerms.get_sections_from_legacy_ccns(@term_yr, @term_cd, ccn_list)
            legacy_sections.each do |section|
              ccn = section['ccn']
              section_metadata = {
                termYr: @term_yr,
                termCd: @term_cd,
                ccn: ccn,
                deptName: section['dept_name'],
                catalogId: section['catalog_id'],
                instructionFormat: section['instruction_format'],
                sectionNumber: section['section_num']
              }
              media = media_per_ccn[ccn]
              feed << media.merge(section_metadata)
            end
          else
            courses = @academics.courses_list_from_ccns(@term_yr, @term_cd, media_per_ccn.keys)
            courses.each do |course|
              course[:classes].each do |next_class|
                next_class[:sections].each do |section|
                  ccn = section[:ccn]
                  section_metadata = {
                    termYr: @term_yr,
                    termCd: @term_cd,
                    ccn: ccn,
                    deptName: next_class[:dept],
                    catalogId: next_class[:courseCatalog],
                    instructionFormat: section[:instruction_format],
                    sectionNumber: section[:section_number]
                  }
                  media = media_per_ccn[ccn.to_i]
                  feed << media.merge(section_metadata) if media
                end
              end
            end
          end
        end
      end
      feed
    end

    def extract_authorized(instructors)
      instructors ? instructors.select { |i| %w(1 2 3 5).include? i[:instructor_func] } : []
    end

    def instance_key
      if @term_yr && @term_cd
        "#{Webcast::CourseMedia.id_per_ccn(@term_yr, @term_cd, @ccn_list.to_s)}/#{@uid}"
      else
        @uid
      end
    end

    def merge(media_per_ccn, media_type)
      all_recordings = Set.new
      media_per_ccn.each do |section|
        recordings = section[media_type]
        recordings.each { |r| all_recordings << r } if recordings
      end
      all_recordings.to_a
    end

  end
end
