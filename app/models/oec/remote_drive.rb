module Oec
  class RemoteDrive < GoogleApps::SheetsManager

    HUMAN_URL = 'https://drive.google.com/drive/my-drive'

    def initialize
      super(GoogleApps::CredentialStore::OEC_APP_ID, Settings.oec.google.uid, Settings.oec.google.marshal_dump)
    end

    def check_conflicts_and_copy_file(file, dest_folder, opts={})
      if find_items_by_name(file.name, parent_id: folder_id(dest_folder)).any?
        raise Oec::Tasks::UnexpectedDataError, "File '#{file.name}' already exists in remote drive folder '#{dest_folder.name}'; could not copy"
      elsif (item = copy_item_to_folder(file, folder_id(dest_folder)))
        opts[:on_success].call if opts[:on_success]
        item
      else
        raise RuntimeError, "Could not copy file '#{file.name}' to '#{dest_folder.name}'"
      end
    end

    def check_conflicts_and_create_folder(name, parent=nil, opts={})
      if (existing_folder = find_first_matching_folder(name, parent))
        case opts[:on_conflict]
          when :return_existing
            return existing_folder
          when :error
            raise Oec::Tasks::UnexpectedDataError, "Folder '#{name}' with parent '#{folder_name(parent)}' already exists on remote drive"
        end
      elsif (new_folder = create_folder(name, folder_id(parent)))
        opts[:on_creation].call if opts[:on_creation]
        new_folder
      else
        raise RuntimeError, "Could not create folder '#{name}' on remote drive"
      end
    end

    def check_conflicts_and_upload(item, name, type, folder, opts={})
      if find_items_by_name(name, parent_id: folder_id(folder)).any?
        raise Oec::Tasks::UnexpectedDataError, "Item '#{name}' already exists in remote drive folder '#{folder.name}'; could not upload"
      end
      upload_operation = (type == Oec::Worksheets::Base) ?
        upload_to_spreadsheet(name, item.to_io, folder_id(folder)) :
        upload_file(name, '', folder_id(folder), type, item.to_s)
      unless upload_operation
        raise RuntimeError, "Item '#{name}' could not be uploaded to remote drive folder '#{folder.name}'"
      end
      opts[:on_success].call if opts[:on_success]
      item
    end

    def find_first_matching_folder(name, parent=nil)
      find_folders_by_name(name, parent_id: folder_id(parent)).first
    end

    def find_first_matching_item(name, parent=nil)
      find_items_by_name(name, parent_id: folder_id(parent)).first
    end

    def find_nested(folder_names, opts={})
      folder_names.inject(nil) do |parent, name|
        if !(item = find_first_matching_item(name, parent))
          case opts[:on_failure]
          when :error
            raise Oec::Tasks::UnexpectedDataError, "Could not locate folder '#{name}' with parent '#{folder_name(parent)}' on remote drive"
          else
            return nil
          end
        end
        item
      end
    end

  end
end
