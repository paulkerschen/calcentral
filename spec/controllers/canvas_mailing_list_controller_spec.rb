describe CanvasMailingListController do
  let(:canvas_course_id) { rand(99999) }

  shared_examples 'a protected controller' do
    let(:user_id) { rand(99999).to_s }
    before do
      session['user_id'] = user_id
      allow_any_instance_of(Canvas::SisUserProfile).to receive(:get).and_return({
        'id' => user_id
      })
      allow_any_instance_of(Canvas::Admins).to receive(:admin_user?).with(user_id).and_return(is_admin)
      allow(Canvas::CourseUser).to receive(:new).with(user_id: user_id, course_id: canvas_course_id).and_return(
        double(course_user: course_user)
      )
    end

    after do
      MailingLists::SiteMailingList.destroy_all
    end

    let(:welcome_email_body) { 'A most welcome body' }
    let(:welcome_email_subject) { 'A most welcome subject' }

    shared_examples 'not authorized' do
      it 'forbids list lookup' do
        expect(MailingLists::SiteMailingList).to_not receive(:find_or_initialize_by)
        lookup_request
        expect(response.status).to eq(403)
      end

      it 'forbids list creation' do
        expect(MailingLists::MailgunList).to_not receive(:create!)
        create_request
        expect(response.status).to eq(403)
      end

      it 'forbids welcome email activation' do
        expect(MailingLists::SiteMailingList).to_not receive(:find_by)
        email_activate_request
        expect(response.status).to eq(403)
      end

      it 'forbids welcome email deactivation' do
        expect(MailingLists::SiteMailingList).to_not receive(:find_by)
        email_deactivate_request
        expect(response.status).to eq(403)
      end

      it 'forbids welcome email update' do
        expect(MailingLists::SiteMailingList).to_not receive(:find_by)
        email_update_request
        expect(response.status).to eq(403)
      end

      it 'forbids message log' do
        expect(MailingLists::SiteMailingList).to_not receive(:find_by)
        download_email_log_request
        expect(response.status).to eq(403)
      end
    end

    shared_examples 'authorized' do
      it 'allows list lookup' do
        expect(MailingLists::SiteMailingList).to receive(:find_or_initialize_by).and_call_original
        lookup_request
        expect(response.status).to eq 200
        response_json = JSON.parse(response.body)
        expect(response_json['mailingList']['state']).to eq 'unregistered'
      end

      it 'allows list creation' do
        expect(MailingLists::MailgunList).to receive(:create!).and_call_original
        create_request
        expect(response.status).to eq 200
        response_json = JSON.parse(response.body)
        expect(response_json['mailingList']['state']).to eq 'created'
      end

      context 'welcome emails' do
        before { expect(MailingLists::SiteMailingList).to receive(:find_by).at_least(:once).and_call_original }
        context 'nonexistent course site' do
          it 'refuses activation' do
            email_activate_request
            expect(response.status).to eq 400
          end

          it 'refuses deactivation' do
            email_deactivate_request
            expect(response.status).to eq 400
          end

          it 'refuses updates' do
            email_update_request
            expect(response.status).to eq 400
          end

          it 'refuses message log' do
            download_email_log_request
            expect(response.status).to eq 400
          end
        end

        context 'existent course site' do
          before { create_request }
          context 'activation' do          
            it 'allows activation' do
              email_update_request
              email_activate_request
              expect(response.status).to eq 200
              response_json = JSON.parse(response.body)
              expect(response_json['welcomeEmailActive']).to eq true
            end

            context 'no email content set' do
              it 'returns error' do
                email_activate_request
                expect(response.status).to eq 400
              end
            end

            context 'no email body' do
              let(:welcome_email_body) { nil }
              it 'returns error' do
                email_update_request
                email_activate_request
                expect(response.status).to eq 400
              end
            end

            context 'no email subject' do
              let(:welcome_email_subject) { nil }
              it 'returns error' do
                email_update_request
                email_activate_request
                expect(response.status).to eq 400
              end
            end
          end

          context 'serving CSV sent message log' do
            let(:csv_string) do
              [
                "Name,Email address,Message sent,Current member",
                "A. Aardvark,a@berkeley.edu,,Y",
                "B. Boa,b@berkeley.edu,,Y",
                "C. Curlew,c@berkeley.edu,,Y",
                "D. Dugong,d@berkeley.edu,,Y",
              ].join("\n")
            end
            before { allow_any_instance_of(MailingLists::SiteMailingList).to receive(:members_welcomed_csv).and_return(csv_string) }
            it 'is allowed' do
              download_email_log_request
              expect(response.status).to eq(200)
              expect(response.headers['Content-Type']).to eq 'text/csv'
              expect(response.headers['Content-Disposition']).to start_with 'attachment; filename'
            end
          end

          context 'deactivation' do
            it 'is allowed' do
              email_deactivate_request
              expect(response.status).to eq 200
              response_json = JSON.parse(response.body)
              expect(response_json['welcomeEmailActive']).to eq false
            end
          end

          context 'update' do
            it 'is allowed' do
              email_update_request
              expect(response.status).to eq 200
              response_json = JSON.parse(response.body)
              expect(response_json['mailingList']['welcomeEmailActive']).to eq false
              expect(response_json['mailingList']['welcomeEmailBody']).to eq welcome_email_body
              expect(response_json['mailingList']['welcomeEmailSubject']).to eq welcome_email_subject
            end

            context 'no body provided' do
              let(:welcome_email_body) { nil }
              it 'returns error' do
                email_update_request
                expect(response.status).to eq 400
              end
            end

            context 'no subject provided' do
              let(:welcome_email_subject) { nil }
              it 'returns error' do
                email_update_request
                expect(response.status).to eq 400
              end
            end          
          end
        end
      end
    end

    context 'when user is not in the course site' do
      let(:is_admin) { false }
      let(:course_user) { nil }
      include_examples 'not authorized'
    end

    context 'when user is a student in the course site' do
      let(:is_admin) { false }
      let(:course_user) { {'enrollments' => [{'role' => 'StudentEnrollment'}]} }
      include_examples 'not authorized'
    end

    context 'when user is a teacher in the course site' do
      let(:is_admin) { false }
      let(:course_user) { {'enrollments' => [{'role' => 'TeacherEnrollment'}]} }
      include_examples 'authorized'
    end

    context 'when user is a Canvas admin' do
      let(:is_admin) { true }
      let(:course_user) { nil }
      include_examples 'authorized'
    end
  end

  let(:make_request) { lookup_request }

  context 'in CalCentral context with explicit Canvas course ID' do
    let(:lookup_request) { get :show, params: {canvas_course_id: canvas_course_id.to_s} }
    let(:create_request) { post :create, params: {canvas_course_id: canvas_course_id.to_s} }
    let(:download_email_log_request) { get :download_welcome_email_log, params: {canvas_course_id: canvas_course_id.to_s, format: 'csv'} }
    let(:email_activate_request) { post :activate_welcome_email, params: {canvas_course_id: canvas_course_id.to_s} }
    let(:email_deactivate_request) { post :deactivate_welcome_email, params: {canvas_course_id: canvas_course_id.to_s} }
    let(:email_update_request) { post :update_welcome_email, params: {canvas_course_id: canvas_course_id.to_s, subject: welcome_email_subject, body: welcome_email_body} }
    it_behaves_like 'a user authenticated api endpoint'
    it_behaves_like 'a protected controller'
  end

  context 'in LTI context' do
    let(:lookup_request) { get :show, params: {canvas_course_id: 'embedded'} }
    let(:create_request) { post :create, params: {canvas_course_id: 'embedded'} }
    let(:download_email_log_request) { get :download_welcome_email_log, params: {canvas_course_id: 'embedded', format: 'csv'} }
    let(:email_activate_request) { post :activate_welcome_email, params: {canvas_course_id: 'embedded'} }
    let(:email_deactivate_request) { post :deactivate_welcome_email, params: {canvas_course_id: 'embedded'} }
    let(:email_update_request) { post :update_welcome_email, params: {canvas_course_id: 'embedded', subject: welcome_email_subject, body: welcome_email_body} }

    before do
      session['canvas_course_id'] = canvas_course_id.to_s
    end
    it_behaves_like 'a protected controller'
  end
end
