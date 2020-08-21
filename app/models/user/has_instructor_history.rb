module User
  class HasInstructorHistory < UserSpecificModel

    extend Cache::Cacheable
    include Cache::UserCacheExpiry

    def has_instructor_history?(current_terms = nil)
      self.class.fetch_from_cache "#{@uid}-" + (current_terms && current_terms.collect {|t| t.slug}).to_s do
        EdoOracle::Queries.has_instructor_history?(@uid, current_terms)
      end
    end
  end
end
