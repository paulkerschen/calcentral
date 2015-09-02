module CampusSolutions
  class EmailController < CampusSolutionsController

    def post
      post_passthrough CampusSolutions::MyEmail
    end

    def delete
      delete_passthrough CampusSolutions::MyEmail
    end

  end
end
