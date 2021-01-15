module MailingLists
  class SiteMailingList < ApplicationRecord
    include ActiveRecordHelper
    include ClassLogger
    include DatedFeed

    self.table_name = 'canvas_site_mailing_lists'

    attr_accessor :request_failure
    attr_accessor :population_results

    validate :catch_request_failure

    validates :canvas_site_id, presence: {message: 'ID must be a numeric string.'}
    validates :canvas_site_id, uniqueness: {message: 'ID "%{value}" has already reserved a Mailing List.'}

    validates :list_name, uniqueness: {message: '"%{value}" is already in use by another Mailing List.'}
    validates :list_name, format: {
      with: /\A[\w-]+\Z/,
      message: 'may contain only lowercase, numeric, underscore and hyphen characters.',
      allow_blank: true
    }
    validates :list_name, length: {
      minimum: 2,
      maximum: 50,
      message: 'must be between 2 and 50 characters in length.',
      allow_blank: true
    }

    after_initialize :get_canvas_site, if: :new_record?
    after_initialize :init_unregistered, if: :new_record?

    # Subclasses override.
    def self.domain; end

    def active_members
      self.members.where(deleted_at: nil)
    end

    def members_welcomed_csv
      welcomed_members = self.members.where.not(welcomed_at: nil).order(:welcomed_at)
      CSV.generate(row_sep: "\r\n") do |csv|
        csv << ['Name', 'Email address', 'Message sent', 'Current member']
        welcomed_members.each do |m|
          csv << ["#{m.first_name} #{m.last_name}", m.email_address, m.welcomed_at, (m.deleted_at.nil? ? 'Y' : 'N')]
        end
      end
    end

    def populate
      if self.state != 'created'
        self.request_failure = "Mailing List \"#{self.list_name}\" must be created before being populated."
        return
      end

      course_users = Canvas::CourseUsers.new(course_id: self.canvas_site_id).course_users[:body]
      list_members = get_list_members

      if !course_users
        self.request_failure = "Could not retrieve current site roster for \"#{self.list_name}\"."
      elsif !list_members
        self.request_failure = "Could not retrieve existing list roster for \"#{self.list_name}\"."
      else
        update_memberships(course_users, list_members)
        send_welcome_emails if self.welcome_email_active && self.welcome_email_body.present? && self.welcome_email_subject.present?
      end
    end

    def to_json
      feed = {}
      get_canvas_site
      if @canvas_site
        feed[:canvasSite] = {
          canvasCourseId: self.canvas_site_id,
          sisCourseId: @canvas_site['sis_course_id'],
          name: self.canvas_site_name,
          courseCode: @canvas_site['course_code'],
          url: "#{Settings.canvas_proxy.url_root}/courses/#{@canvas_site['id']}",
          term: parse_term(@canvas_site['term'])
        }
        feed[:mailingList] = {
          name: self.list_name,
          domain: self.class.domain,
          state: self.state,
          welcomeEmailActive: self.welcome_email_active,
          welcomeEmailBody: self.welcome_email_body,
          welcomeEmailSubject: self.welcome_email_subject,          
        }
        if self.respond_to? :members
          feed[:mailingList][:welcomeEmailLastSent] = self.members.maximum('welcomed_at')
        end

        add_list_urls feed

        if self.populated_at.present?
          feed[:mailingList][:membersCount] = self.members_count
          feed[:mailingList][:timeLastPopulated] = format_date(self.populated_at.to_datetime)
          if self.population_results || self.populate_add_errors.try(:nonzero?) || self.populate_remove_errors.try(:nonzero?)
            feed[:populationResults] = population_results_for_feed
          end
        end
      end
      feed[:errorMessages] = errors.full_messages if invalid?
      feed.to_json
    end

    private

    # Subclasses may override if they have external administration URLs.
    def add_list_urls(feed); end

    def any_population_failures?
      self.population_results[:add][:failure].any? || self.population_results[:remove][:failure].any?
    end

    def can_send_to_mailing_list?(canvas_course_user)
      Canvas::CourseUser.has_instructing_role?(canvas_course_user) ||
        Canvas::CourseUser.is_project_maintainer?(canvas_course_user) ||
        Canvas::CourseUser.is_project_owner?(canvas_course_user)
    end

    def catch_request_failure
      errors[:base] << self.request_failure if self.request_failure
    end

    def generate_list_name
      # 'CHEM 1A LEC 003' => 'chem-1a-lec-003-sp15'
      # {{design}} => 'design-sp15'
      # 'The "Wild"-"Wild" West?' => 'the-wild-wild-west-sp15'
      # 'Conversation intermédiaire' => 'conversation-intermediaire-sp15'
      # 'Global Health: Disaster Preparedness and Response' => 'global-health-disaster-preparedness-and-respo-sp15'
      if @canvas_site
        normalized_name = I18n.transliterate(@canvas_site['name']).downcase.split(/[^a-z0-9]+/).reject(&:blank?).join('-').slice(0, 45)
        if (term = Canvas::Terms.sis_term_id_to_term @canvas_site['term']['sis_term_id'])
          normalized_name << "-#{Berkeley::TermCodes.to_abbreviation(term[:term_yr], term[:term_cd])}"
        else
          normalized_name << '-list'
        end
        normalized_name
      end
    end

    def get_canvas_site
      return if self.canvas_site_id.blank? || @canvas_site
      if (@canvas_site = Canvas::Course.new(canvas_course_id: self.canvas_site_id).course[:body])
        self.canvas_site_name = @canvas_site['name'].strip
        save if (self.persisted? && self.changed?)
      else
        self.request_failure = "No bCourses site with ID \"#{self.canvas_site_id}\" was found."
      end
    end

    def init_unregistered
      self.state = 'unregistered'
      get_canvas_site
      self.list_name ||= generate_list_name
      if name_available? == false
        self.request_failure = "A Mailing List cannot be created for the site \"#{self.canvas_site_name}\"."
      end
    end

    def initialize_population_results
      self.population_results = {
        add: {
          total: 0,
          success: 0,
          failure: []
        },
        remove: {
          total: 0,
          success: 0,
          failure: []
        },
        update: {
          total: 0,
          success: 0,
          failure: []
        },
        welcome_emails: {
          total: 0,
          success: 0
        }
      }
    end

    def name_available?
      return if list_name.blank?
      MailingLists::SiteMailingList.default_scoped.find_by(list_name: self.list_name).nil?
    end

    def parse_term(term)
      if (parsed_term = Canvas::Terms.sis_term_id_to_term(term['sis_term_id']))
        parsed_term.merge(name: Berkeley::TermCodes.to_english(parsed_term[:term_yr], parsed_term[:term_cd]))
      end
    end

    def population_results_for_feed
      messages = []
      if self.population_results
        success = population_results[:add][:failure].empty? && population_results[:remove][:failure].empty?
        if success
          messages << population_results_to_english(
            [population_results[:add][:success], 'added', true],
            [population_results[:remove][:success], 'removed', true],
            [population_results[:update][:success], 'updated', true]
          )
        else
          messages << population_results_to_english(
            [population_results[:add][:failure].count, 'added', false],
            [population_results[:remove][:failure].count, 'removed', false],
            [population_results[:update][:failure].count, 'updated', false]
          )
        end
      elsif self.populate_add_errors.nonzero? || self.populate_remove_errors.nonzero?
        messages << population_results_to_english(
          [self.populate_add_errors, 'added', false],
          [self.populate_remove_errors, 'removed', false]
        )
        success = false
      end
      {
        success: success,
        messages: messages.compact
      }
    end

    def population_results_to_english(*components)
      english_components = components.map do |component|
        count, action, success = component
        next if count.zero?
        message = "#{count} "
        message << 'new ' if action == 'added'
        message << 'former ' if action == 'removed'
        message << 'member'
        message << 's' if count > 1
        if success
          message << (count > 1 ? ' were ' : ' was ')
        else
          message << ' could not be '
        end
        message << action
      end
      english_components.compact!
      english_components.join('; ').concat('.') if english_components.any?
    end

    def update_memberships(course_users, list_members)
      # List members are keyed by email addresses; keep track of any needed removals in a separate set.
      addresses_to_remove = list_members.select{ |k, v| v.deleted_at.nil? }.keys.to_set

      # Note UIDs for users with send permission, defined for now as having a teacher role in the course site,
      # or an Owner or Maintainer role in a project site.
      sender_uids = Set.new
      course_users.each { |user| sender_uids << user['login_id'] if can_send_to_mailing_list?(user) }

      logger.info "Starting population of mailing list #{self.list_name} for course site #{self.canvas_site_id}."
      initialize_population_results

      population_results[:initial_count] = list_members.count

      course_users.map{ |user| user['login_id'] }.each_slice(1000) do |uid_slice|
        User::BasicAttributes.attributes_for_uids(uid_slice).each do |user|

          user[:can_send] = sender_uids.include?(user[:ldap_uid])

          # In general we want to use official berkeley.edu email addresses sourced from User::BasicAttributes.
          # However, we may wish to override with Canvas-sourced email addresses for testing purposes.
          # Note that the course_users list will not include email addresses for any members with
          # "enrollment_state": "invited".
          user_address = case Settings.canvas_mailing_lists.preferred_email_address_source
            when 'ldapAlternateId'
              user[:official_bmail_address] || user[:email_address]
            when 'ldapMail'
              user[:email_address] || user[:official_bmail_address]
            when 'canvas'
              if (canvas_user = course_users.find { |course_user| course_user['login_id'] == user[:ldap_uid] })
                logger.info "Setting email address for UID #{user[:ldap_uid]} to Canvas-sourced address #{canvas_user['email']}"
                canvas_user['email']
              else
                user[:official_bmail_address] || user[:email_address]
              end
          end

          if user_address
            user_address.downcase!
            addresses_to_remove.delete user_address
            if list_members.has_key? user_address
              # Address is in the list but deleted; reactivate with latest data.
              if list_members[user_address].deleted_at
                population_results[:add][:total] += 1
                logger.debug "Reactivating previously deleted address #{user_address}"
                if reactivate_member(list_members[user_address], user)
                  population_results[:add][:success] += 1
                else
                  population_results[:add][:failure] << user_address
                end
              # Address is in the list and active; check if any data needs updating.
              elsif update_required?(list_members[user_address], user)
                population_results[:update][:total] += 1
                logger.debug "Updating address #{user_address}"
                if update_member(list_members[user_address], user)
                  population_results[:update][:success] += 1
                else
                  population_results[:update][:failure] << user_address
                end
              end
            else
              # Address is not currently in the list; add it.
              population_results[:add][:total] += 1
              logger.debug "Adding address #{user_address}"
              if add_member(user_address, user[:first_name], user[:last_name], user[:can_send])
                population_results[:add][:success] += 1
              else
                population_results[:add][:failure] << user_address
              end
            end
          else
            logger.warn "No email address found for UID #{user[:ldap_uid]}"
          end
        end
      end

      population_results[:remove][:total] = addresses_to_remove.count

      addresses_to_remove.each do |address|
        logger.debug "Removing address #{address}"
        if remove_member address
          population_results[:remove][:success] += 1
        else
          population_results[:remove][:failure] << address
        end
      end

      log_population_results

      logger.info "Finished population of mailing list #{self.list_name}."
      self.populate_add_errors = population_results[:add][:failure].count
      self.populate_remove_errors = population_results[:remove][:failure].count
      self.populated_at = DateTime.now
      save
    end

    def send_welcome_emails
      payload = {
        'from' => 'bCourses Mailing Lists <no-reply@bcourses-mail.berkeley.edu>',
        'subject' => self.welcome_email_subject,
        'html' => self.welcome_email_body,
        'text' => text_format_email(self.welcome_email_body)
      }

      unwelcomed_members = active_members.where(welcomed_at: nil)
      population_results[:welcome_emails][:total] = unwelcomed_members.count
      unwelcomed_members.each_slice(1000) do |unwelcomed_slice|
        recipient_fields = MailingLists::OutgoingMessage.get_recipient_fields unwelcomed_slice
        response = Mailgun::SendMessage.new.post payload.merge(recipient_fields)
        break unless response.try(:[], :response).try(:[], :sending)
        ActiveRecord::Base.transaction do
          unwelcomed_slice.each { |member| member.update(welcomed_at: DateTime.now) }
        end
        population_results[:welcome_emails][:success] += unwelcomed_slice.count
      end
    end

    def text_format_email(body)
      # Before stripping HTML tags, replace end tags on block elements with a couple of line breaks.
      spaced_body = body.gsub(/(<\/[ol|ul|p]>)\s*/, '\\1' + "\n\n")
      HtmlSanitizer.sanitize_html spaced_body
    end
  end
end
