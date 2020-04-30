describe Canvas::CourseSettings do

  let(:canvas_course_id)    { '1121' }
  subject                   { Canvas::CourseSettings.new(course_id: canvas_course_id) }

  context 'when requesting course settings from canvas' do
    context 'if course exists in canvas' do
      it 'returns course settings hash' do
        settings = subject.settings[:body]
        expect(settings['allow_student_discussion_topics']).to eq true
        expect(settings['allow_student_forum_attachments']).to eq false
        expect(settings['allow_student_discussion_editing']).to eq true
        expect(settings['grading_standard_enabled']).to eq true
        expect(settings['grading_standard_id']).to eq 0
      end

      it 'uses cache by default' do
        expect(Canvas::CourseSettings).to receive(:fetch_from_cache).and_return({cached: 'hash'})
        settings = subject.settings
        expect(settings[:cached]).to eq 'hash'
      end

      it 'bypasses cache when cache option is false' do
        expect(Canvas::CourseSettings).not_to receive(:fetch_from_cache)
        settings = subject.settings(cache: false)[:body]
        expect(settings['allow_student_discussion_topics']).to eq true
      end
    end

    context 'if course does not exist in canvas' do
      before { subject.on_request(method: :get).set_response(status: 404, body: '{"errors":[{"message":"The specified resource does not exist."}],"error_report_id":121214508}') }
      it 'returns a 404 response' do
        settings = subject.settings
        expect(settings[:statusCode]).to eq 404
        expect(settings[:error]).to be_present
        expect(settings).not_to include :body
      end
    end

    context 'on request failure' do
      let(:failing_request) { {method: :get} }
      let(:response) { subject.settings }
      it_should_behave_like 'an unpaged Canvas proxy handling request failure'
    end
  end

  describe '#fix_default_view' do
    let(:default_home_page) { 'modules' }
    let(:preferred_home_page) { 'feed' }
    let(:original_course_properties) do
      {
        'id'=>canvas_course_id,
        'default_view'=> default_home_page,
        'workflow_state'=>'unpublished'
      }
    end
    let(:change_request) do
      stub_request(:put, /.*\/courses\/#{canvas_course_id}/)
        .with(body: "#{URI.encode_www_form_component('course[default_view]')}=#{preferred_home_page}")
        .to_return(status: 200, body: {id: canvas_course_id, default_view: preferred_home_page}.to_json)
    end
    it 'sets the site home page to Activity Stream if needed' do
      subject.fix_default_view original_course_properties
      expect(change_request).to have_been_requested
    end
    context 'when the site home page is initialized in our preferred way' do
      let(:default_home_page) { preferred_home_page }
      it 'leaves well enough alone' do
        subject.fix_default_view original_course_properties
        expect(change_request).not_to have_been_requested
      end
    end
  end

end
