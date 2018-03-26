namespace :data_loch do

  desc 'Upload course and enrollment data snapshot to data loch S3 (TERM_ID = 2XXX)'
  task :snapshot => :environment do
    term_id = ENV['TERM_ID']
    if term_id.blank?
      Rails.logger.error 'Must specify TERM_ID=4DigitCampusSolutionsTermId'
    end

    Rails.logger.warn "Starting course and enrollment data snapshot for term #{term_id}."
    Rails.logger.warn 'Disabling slow query logger for this task.'
    ActiveSupport::Notifications.unsubscribe 'sql.active_record'

    s3 = DataLoch::S3.new

    courses_path = DataLoch::Zipper.zip_courses term_id
    s3.upload_to_term(courses_path, term_id)
    FileUtils.rm courses_path
    Rails.logger.info 'Course snapshot uploaded.'

    enrollments_path = DataLoch::Zipper.zip_enrollments term_id
    s3.upload_to_term(enrollments_path, term_id)
    FileUtils.rm enrollments_path
    Rails.logger.info 'Enrollment snapshot uploaded.'
  end

end
