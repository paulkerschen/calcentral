module GoogleApps
  class DriveManager
    include ClassLogger

    # See https://github.com/googleapis/google-api-ruby-client#errors--retries
    Google::Apis::RequestOptions.default.retries = Settings.google_proxy.max_retries

    def initialize(app_id, uid, options = {})
      @app_id = app_id
      @uid = uid
      @options = options
    end

    def get_items_in_folder(parent_id, mime_type = nil)
      options = { parent_id: parent_id }
      options.merge!(mime_type: mime_type) unless mime_type.nil?
      find_items options
    end

    def find_folders_by_name(name, options = {})
      options.merge!(mime_type: 'application/vnd.google-apps.folder')
      find_items_by_name(name, options)
    end

    def find_folders(parent_id = 'root')
      find_items(mime_type: 'application/vnd.google-apps.folder', parent_id: parent_id)
    end

    def find_items_by_name(name, options = {})
      find_items options.merge(name: name)
    end

    def download(file, destination)
      drive_api.get_file(file.id, download_dest: destination)
    rescue Google::Apis::ClientError => e
      raise Errors::ProxyError, "Failed to download '#{file.name}' (id: #{file.id}).\nError: #{e.message}"
    end

    def download_string(file)
      strio = StringIO.new
      download(file, strio)
      strio.string
    end

    def find_items(options = {})
      items = []
      query = 'trashed=false'
      parent_id = options[:parent_id]
      # Shared items will not be found under our own root folder.
      unless parent_id || options[:shared]
        parent_id = 'root'
      end
      query.concat " and '#{parent_id}' in parents" if parent_id
      query.concat " and name='#{escape options[:name]}'" if options.has_key? :name
      query.concat " and mimeType='#{options[:mime_type]}'" if options.has_key? :mime_type
      query.concat ' and sharedWithMe' if options[:shared]
      page_token = nil
      begin
        args = {q: query}
        args[:page_token] = page_token unless page_token.nil?
        result = drive_api.list_files(args)
        items.concat result.files
        page_token = result.next_page_token
      rescue Google::Apis::ClientError => e
        raise Errors::ProxyError, "Error in find_items(#{options}): #{e.message}"
      end while page_token.to_s != ''
      items
    end

    def create_folder(name, parent_id='root')
      metadata = Google::Apis::DriveV3::File.new(
        name: name,
        parents: [parent_id],
        mime_type: 'application/vnd.google-apps.folder'
      )
      drive_api.create_file(metadata)
    rescue Google::Apis::ClientError => e
      raise Errors::ProxyError, "Error in create_folder(#{name}, ...): #{e.message}"
    end

    def upload_file(name, description, parent_id, mime_type, file_path, content_type=nil)
      metadata = Google::Apis::DriveV3::File.new(
        name: name,
        description: description,
        mime_type: mime_type
      )
      # Target directory is optional
      metadata.parents = [parent_id] if parent_id
      drive_api.create_file(metadata, upload_source: file_path, content_type: (content_type || mime_type))
    rescue Google::Apis::ClientError => e
      raise Errors::ProxyError, "Error in upload_file(#{name}): #{e.message}"
    end

    def copy_item_to_folder(item, folder_id, copy_name=nil)
      copy_name ||= item.name
      metadata = Google::Apis::DriveV3::File.new(
        name: copy_name,
        parents: [folder_id],
      )
      drive_api.copy_file(item.id, metadata)
    rescue Google::Apis::ClientError => e
      raise Errors::ProxyError, "Error in copy_item_to_folder(#{copy_name}): #{e.message}"
    end

    def copy_item(id, copy_name)
      metadata = Google::Apis::DriveV3::File.new(name: copy_name)
      drive_api.copy_file(id, metadata)
    rescue Google::Apis::ClientError => e
      raise Errors::ProxyError, "Error in copy_item(#{id}): #{e.message}"
    end

    def folder_id(folder)
      folder ? folder.id : 'root'
    end

    def folder_name(folder)
      folder ? folder.name : 'root'
    end

    private

    def drive_api
      unless @drive_api
        @drive_api ||= Google::Apis::DriveV3::DriveService.new
        @drive_api.authorization = get_authorization
      end
      @drive_api
    end

    def get_authorization
      GoogleApps::Authorization.new(@uid, @app_id).get_authorization
    end

    def escape(arg)
      arg.gsub('\'', %q(\\\'))
    end

  end
end
