describe Oec::CourseCode do

  include_context 'OEC course codes'

  it 'should find course codes for a single department' do
    course_codes = Oec::CourseCode.where(dept_code: 'CCHEM').to_a
    expect(course_codes).to have(1).items
    expect(course_codes.first.dept_name).to eq 'CHEM'
    expect(course_codes.first.catalog_id).to eq ''
  end

  it 'should accept department names with weird characters' do
    course_codes = Oec::CourseCode.where(dept_name: 'A,RESEC').to_a
    expect(course_codes).to have(1).items
  end

  it 'should find course codes assigned to department by specific catalog id' do
    course_codes = Oec::CourseCode.where(dept_code: 'IBIBI').to_a
    expect(course_codes).to have(3).items
    expect(course_codes.map &:dept_name).to match_array %w(BIOLOGY BIOLOGY INTEGBI)
    expect(course_codes.map &:catalog_id).to match_array ['1B', '1BL', '']
  end

  it 'should find course codes listed under subdepartments' do
    course_codes = Oec::CourseCode.where(dept_code: 'LPSPP').to_a
    expect(course_codes).to have(5).items
    expect(course_codes.map &:dept_name).to match_array %w(CATALAN ILA PORTUG SPANISH SPANISH)
    expect(course_codes.map &:catalog_id).to match_array ['', '', '', '', '99']
  end

  it 'should allow omission of non-included course codes' do
    course_codes = Oec::CourseCode.where(dept_code: 'LPSPP', include_in_oec: true).to_a
    expect(course_codes).to have(4).items
    expect(course_codes.map &:dept_name).to match_array %w(CATALAN ILA PORTUG SPANISH)
    expect(course_codes.map &:catalog_id).to match_array ['', '', '', '']
  end

  it 'should allow course-code-specific mappings to coexist with wildcard blank mapping' do
    Oec::CourseCode.create(dept_name: 'SPANISH', catalog_id: '399', dept_code: 'XDEPT', include_in_oec: true)
    xdept_course_codes = Oec::CourseCode.where(dept_code: 'XDEPT').to_a
    expect(xdept_course_codes).to have(1).items
    span_port_course_codes = Oec::CourseCode.where(dept_code: 'LPSPP').to_a
    expect(span_port_course_codes).to have(5).items
  end

  it 'should not allow duplicate course-code-specific mappings' do
    expect { Oec::CourseCode.create(dept_name: 'BIOLOGY', catalog_id: '1A', dept_code: 'SHIST', include_in_oec: true) }.to raise_error ActiveRecord::RecordNotUnique
  end

  it 'should not allow duplicate wildcard blank mappings' do
    expect { Oec::CourseCode.create(dept_name: 'SPANISH', catalog_id: '', dept_code: 'SHIST', include_in_oec: true) }.to raise_error ActiveRecord::RecordNotUnique
  end

end
