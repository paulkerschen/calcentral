module EdoOracle
  module UserCourses
    class Instructing < Base

      include Cache::UserCacheExpiry

      def get_courses_instructing(terms=nil)
        cache_key = terms ? "#{@uid}-#{terms.map{ |t| t[:slug]}.join(',')}" : @uid
        self.class.fetch_from_cache(cache_key) do
          campus_classes = {}
          merge_instructing(campus_classes, terms)
          sort_courses campus_classes
          # Sort the hash in descending order of semester.
          campus_classes = Hash[campus_classes.sort.reverse]
          # Merge each section's schedule, location, and instructor list.
          merge_detailed_section_data(campus_classes)
          campus_classes
        end
      end

    end
  end
end
