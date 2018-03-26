module DataLoch
  class S3

    def initialize
      @resource = Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(Settings.data_loch.aws_key, Settings.data_loch.aws_secret),
        region: Settings.data_loch.aws_region
      )
    end

    def upload_to_term(local_path, term_id)
      today = DateTime.now.strftime('%Y-%m-%d')
      digest = Digest::MD5.hexdigest today
      key = "#{Settings.data_loch.prefix}/term/#{term_id}/#{digest}-#{today}/#{File.basename local_path}"
      @resource.bucket(Settings.data_loch.bucket).object(key).upload_file local_path, server_side_encryption: 'AES256'
    end

  end
end
