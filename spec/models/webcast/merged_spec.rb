describe Webcast::Merged do

  context 'authorized user and a fake proxy' do
    let(:user_id) { random_id }
    let(:options) { { fake: true } }
    let(:policy) do
      AuthenticationStatePolicy.new(AuthenticationState.new('user_id' => user_id), nil)
    end
    before do
      allow(Berkeley::TermCodes).to receive(:legacy?).and_return false
    end

    context 'no matching course' do
      let(:feed) do
        Webcast::Merged.new(user_id, policy, 2014, 'B', [1], options).get_feed
      end
      before do
        expect_any_instance_of(Berkeley::Teaching).not_to receive :new
      end
      it 'returns system status when authenticated' do
        expect(feed[:media]).to be_nil
        # Verify backwards compatibility
        expect(feed[:videos]).to be_nil
      end
    end

    context 'one matching course' do
      let(:feed) do
        Webcast::Merged.new(user_id, policy, 2014, 'B', [1, 87432], options).get_feed
      end
      before do
        courses_list = [
          {
            classes: [
              {
                dept: 'PLANTBI',
                courseCatalog: '150',
                sections: [
                  { ccn: '87435', section_number: '101', instruction_format: 'LAB' },
                  { ccn: '87438', section_number: '102', instruction_format: 'LAB' },
                  { ccn: '87444', section_number: '201', instruction_format: 'LAB' },
                  { ccn: '87447', section_number: '202', instruction_format: 'LAB' },
                  { ccn: '87432', section_number: '001', instruction_format: 'LEC' },
                  { ccn: '87441', section_number: '002', instruction_format: 'LEC' }
                ]
              }
            ]
          }
        ]
        expect_any_instance_of(Berkeley::Teaching).to receive(:courses_list_from_ccns).once.and_return courses_list
      end
      it 'returns one match media' do
        stat_131 = feed[:media][0]
        expect(stat_131[:termYr]).to eq 2014
        expect(stat_131[:termCd]).to eq 'B'
        expect(stat_131[:ccn]).to eq '87432'
        expect(stat_131[:deptName]).to eq 'PLANTBI'
        expect(stat_131[:catalogId]).to eq '150'
        videos = stat_131[:videos]
        expect(videos).to have(31).items
        # Verify backwards compatibility
        expect(feed[:videos]).to eq videos
      end
    end

    context 'ccn formatting per convention' do
      let(:feed) do
        Webcast::Merged.new(user_id, policy, 2008, 'D', [9688], options).get_feed
      end
      before do
        courses_list = [
          {
            classes: [
              {
                sections: [
                  {
                    ccn: '09688',
                    section_number: '101',
                    instruction_format: 'LEC'
                  }
                ]
              }
            ]
          }
        ]
        expect_any_instance_of(Berkeley::Teaching).to receive(:courses_list_from_ccns).once.and_return courses_list
      end
      it 'pads ccn with zeroes' do
        law_course = feed[:media][0]
        expect(law_course).to_not be_nil
        expect(law_course[:ccn]).to eq '09688'
        expect(law_course[:videos]).to be_empty
      end
    end

    context 'two matching course' do
      let(:ldap_uid) { '248421' }
      let(:policy) do
        AuthenticationStatePolicy.new(AuthenticationState.new('user_id' => ldap_uid), nil)
      end
      let(:feed) do
        Webcast::Merged.new(ldap_uid, policy, 2014, 'B', [87432, 76207, 7620], options).get_feed
      end
      before do
        sections_with_recordings = [
          {
            classes: [
              {
                sections: [
                  {
                    ccn: '76207',
                    instruction_format: 'LEC',
                    section_number: '101'
                  },
                  {
                    ccn: '87432',
                    instruction_format: 'LEC',
                    section_number: '101'
                  }
                ]
              }
            ]
          }
        ]
        expect_any_instance_of(Berkeley::Teaching).to receive(:courses_list_from_ccns).with(2014, 'B', [87432, 76207]).and_return sections_with_recordings
      end

      it 'returns course media' do
        expect(feed[:videoErrorMessage]).to be_nil
        media = feed[:media]
        expect(media).to have(2).items
        pb_health_241 = media[0]
        stat_131 = media[1]
        expect(stat_131[:ccn]).to eq '87432'
        expect(stat_131[:videos]).to have(31).items
        expect(stat_131[:instructionFormat]).to eq 'LEC'
        expect(stat_131[:sectionNumber]).to eq '101'
        expect(pb_health_241[:ccn]).to eq '76207'
        expect(pb_health_241[:youTubePlaylist]).to eq '-XXv-cvA_iBacs-uhTVhDhip4sGWoq2C'
        expect(pb_health_241[:videos]).to have(35).items
        expect(feed[:videos]).to match_array(pb_health_241[:videos] + stat_131[:videos])
      end
    end

    context 'cross-listed CCNs in merged feed' do
      let(:feed) do
        Webcast::Merged.new(user_id, policy, 2015, 'B', [51990, 5915, 51992], options).get_feed
      end
      before do
        sections_with_recordings = [
          {
            classes: [
              {
                sections: [
                  { ccn: '05915', section_number: '101', instruction_format: 'LEC' },
                  { ccn: '51990', section_number: '201', instruction_format: 'LEC' }
                ]
              }
            ]
          }
        ]
        expect_any_instance_of(Berkeley::Teaching).to receive(:courses_list_from_ccns).with(2015, 'B', [51990, 5915]).and_return sections_with_recordings
      end
      it 'returns course media' do
        expect(feed[:videoErrorMessage]).to be_nil
        media = feed[:media]
        # These are cross-listed CCNs so we only include unique recordings
        section_101 = media[0][:videos]
        expect(section_101).to have(28).items
        expect(section_101).to match_array media[1][:videos]
      end
    end
  end
end
