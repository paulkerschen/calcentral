module MailingLists
  class Member < ApplicationRecord
    include ActiveRecordHelper
    include ClassLogger

    belongs_to :mailing_list, class_name: 'MailingLists::SiteMailingList', foreign_key: 'mailing_list_id'

    self.table_name = 'canvas_site_mailing_list_members'

  end
end
