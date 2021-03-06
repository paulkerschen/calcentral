module CampusSolutions
  class MyHolds < UserSpecificModel

    include Cache::LiveUpdatesEnabled
    include Cache::FreshenOnWarm
    include Cache::JsonAddedCacher
    include CampusSolutions::HoldsFeatureFlagged

    def get_feed_internal
      return {} unless is_feature_enabled
      CampusSolutions::Holds.new({user_id: @uid}).get
    end

  end
end
