describe User::HasInstructorHistory do
  let(:uid) { '2050' }

  describe 'has_instructor_history?' do
    let(:legacy_term) { double(:term, :legacy? => true, :slug => 'spring-2016') }
    let(:non_legacy_term) { double(:term, :legacy? => false, :slug => 'fall-2016') }
    let(:current_terms) { [non_legacy_term, legacy_term] }
    let(:is_sisedo_instructor) { false }
    before do
      allow(EdoOracle::Queries).to receive(:has_instructor_history?).and_return(is_sisedo_instructor)
    end
    subject { described_class.new(uid).has_instructor_history?(current_terms) }

    context 'when user is not an instructor in sisedo' do
      it {should eq false}
    end

    context 'when user is an instructor in sisedo system' do
      let(:is_sisedo_instructor) { true }
      it {should eq true}
    end
  end

end
