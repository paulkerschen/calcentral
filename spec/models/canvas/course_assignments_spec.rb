describe Canvas::CourseAssignments do

  let(:user_id)             { 2050 }
  let(:canvas_course_id)    { 1234001 }
  subject                   { Canvas::CourseAssignments.new(:course_id => canvas_course_id) }

  it 'provides course assignments' do
    assignments = subject.course_assignments
    expect(assignments.count).to eq 2
    expect(assignments[0]['id']).to eq 6175848
    expect(assignments[0]['name']).to eq 'Assignment 1'
    expect(assignments[0]['description']).to eq '<p>Assignment 1 description</p>'
    expect(assignments[0]['muted']).to eq false
    expect(assignments[0]['due_at']).to eq '2015-05-12T19:40:00Z'
    expect(assignments[0]['points_possible']).to eq 100

    expect(assignments[1]['id']).to eq 6175849
    expect(assignments[1]['name']).to eq 'Assignment 2'
    expect(assignments[1]['description']).to eq '<p>Assignment 2 description</p>'
    expect(assignments[1]['muted']).to eq true
    expect(assignments[1]['due_at']).to eq nil
    expect(assignments[1]['points_possible']).to eq 50
  end

  context 'on request failure' do
    let(:failing_request) { {method: :get} }
    let(:response) { subject.assignments_response }
    it_should_behave_like 'a paged Canvas proxy handling request failure'
  end
end
