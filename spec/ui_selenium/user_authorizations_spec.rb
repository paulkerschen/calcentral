describe 'User authorization', :testui => true, :order => :defined do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    timeout = WebDriverUtils.page_load_timeout

    before(:each) do
      @driver = WebDriverUtils.launch_browser
    end

    after(:each) do
      WebDriverUtils.quit_browser(@driver)
    end

    describe 'View-as' do

      context 'when an admin has viewed-as' do

        before(:example) do
          splash_page = CalCentralPages::SplashPage.new(@driver)
          splash_page.load_page
          splash_page.basic_auth UserUtils.admin_uid
          @toolbox_page = CalCentralPages::MyToolboxPage.new(@driver)
          @toolbox_page.load_page
          @toolbox_page.clear_all_saved_users
          @toolbox_page.clear_all_recent_users
          @toolbox_page.view_as_user('61889')
          cal_net_auth_page = CalNetAuthPage.new(@driver)
          cal_net_auth_page.login(UserUtils.oski_username, UserUtils.oski_password)
          cal_net_auth_page.wait_until(timeout) { cal_net_auth_page.logout_conf_heading_element.visible? }
          splash_page.load_page
          splash_page.basic_auth UserUtils.admin_uid
          @toolbox_page.load_page
        end
        it 'allows the admin to see recently viewed users' do
          @toolbox_page.wait_until(timeout, 'Recent user did not appear') do
            @toolbox_page.recent_user_view_as_button_elements[0].text == '61889' if @toolbox_page.recent_user_view_as_button_elements.any?
          end
        end
        it 'allows the admin to save recently viewed users' do
          @toolbox_page.recent_users_element.when_present(timeout)
          @toolbox_page.save_first_recent_user
          @toolbox_page.wait_until(timeout, 'Saved user did not appear') do
            @toolbox_page.saved_user_view_as_button_elements[0].text == '61889' if @toolbox_page.saved_user_view_as_button_elements.any?
          end
        end
      end

      context 'when an admin enters unauthorized re-auth credentials' do
        before(:example) do
          splash_page = CalCentralPages::SplashPage.new(@driver)
          splash_page.load_page
          splash_page.basic_auth UserUtils.admin_uid
          toolbox_page = CalCentralPages::MyToolboxPage.new(@driver)
          toolbox_page.load_page
          toolbox_page.view_as_user('61889')
        end
        it 'logs the admin out of CalCentral' do
          cal_net_auth_page = CalNetAuthPage.new(@driver)
          cal_net_auth_page.login(UserUtils.oski_username, UserUtils.oski_password)
          cal_net_auth_page.wait_until(timeout) { cal_net_auth_page.logout_conf_heading_element.visible? }
        end
      end

      context 'when an admin enters invalid re-auth credentials' do
        before(:example) do
          splash_page = CalCentralPages::SplashPage.new(@driver)
          splash_page.load_page
          splash_page.basic_auth UserUtils.admin_uid
          toolbox_page = CalCentralPages::MyToolboxPage.new(@driver)
          toolbox_page.load_page
          toolbox_page.view_as_user('61889')
        end
        it 'locks the admin out of CalCentral' do
          cal_net_auth_page = CalNetAuthPage.new(@driver)
          cal_net_auth_page.login('blah', 'blah')
          cal_net_auth_page.wait_until(timeout) { cal_net_auth_page.password.blank? }
          dashboard_page = CalCentralPages::MyDashboardPage.new(@driver)
          dashboard_page.load_page
          cal_net_auth_page.wait_until(timeout) do
            cal_net_auth_page.username.blank?
            cal_net_auth_page.password.blank?
          end
        end
      end

      context 'when an unauthorized user' do
        before(:example) do
          splash_page = CalCentralPages::SplashPage.new(@driver)
          splash_page.load_page
          splash_page.basic_auth '61889'
          @toolbox_page = CalCentralPages::MyToolboxPage.new(@driver)
          @toolbox_page.load_page
        end
        it 'offers no view-as interface' do
          expect(@toolbox_page.view_as_input_element.visible?).to be false
        end
      end
    end

    describe 'UID / SID conversion' do

      context 'when an admin' do
        before(:example) do
          splash_page = CalCentralPages::SplashPage.new(@driver)
          splash_page.load_page
          splash_page.basic_auth UserUtils.admin_uid
          @toolbox_page = CalCentralPages::MyToolboxPage.new(@driver)
          @toolbox_page.load_page
        end
        it 'allows conversion of UID to SID' do
          @toolbox_page.look_up_user('61889')
          @toolbox_page.wait_until(timeout) do
            @toolbox_page.lookup_results_table?
            @toolbox_page.lookup_results_table_element.rows > 1
          end
          expect(@toolbox_page.lookup_results_table_element[1][0].text).to eql('61889')
          expect(@toolbox_page.lookup_results_table_element[1][1].text).to eql('11667051')
        end
        it 'allows conversion of SID to UID' do
          @toolbox_page.look_up_user('11667051')
          @toolbox_page.wait_until(timeout) do
            @toolbox_page.lookup_results_table?
            @toolbox_page.lookup_results_table_element.rows > 1
          end
          expect(@toolbox_page.lookup_results_table_element[1][0].text).to eql('61889')
          expect(@toolbox_page.lookup_results_table_element[1][1].text).to eql('11667051')
        end
      end

      context 'when an unauthorized user' do
        before(:example) do
          splash_page = CalCentralPages::SplashPage.new(@driver)
          splash_page.load_page
          splash_page.basic_auth '61889'
          @toolbox_page = CalCentralPages::MyToolboxPage.new(@driver)
          @toolbox_page.load_page
        end
        it 'offers no UID/SID conversion interface' do
          expect(@toolbox_page.lookup_input_element.visible?).to be false
        end
      end
    end

    describe 'CC admin' do

      context 'when an admin' do
        before(:example) do
          splash_page = CalCentralPages::SplashPage.new(@driver)
          splash_page.load_page
          splash_page.basic_auth UserUtils.admin_uid
          @driver.get("#{WebDriverUtils.base_url}/ccadmin")
        end
        context 'enters unauthorized re-auth credentials' do
          it 'blocks access to CC admin' do
            cal_net_auth_page = CalNetAuthPage.new(@driver)
            cal_net_auth_page.login(UserUtils.oski_username, UserUtils.oski_password)
            cal_net_auth_page.wait_until(timeout) { cal_net_auth_page.password.blank? }
            dashboard_page = CalCentralPages::MyDashboardPage.new(@driver)
            dashboard_page.load_page
            dashboard_page.wait_for_expected_title?
          end
        end
        context 'enters invalid re-auth credentials' do
          it 'blocks access to CC admin' do
            cal_net_auth_page = CalNetAuthPage.new(@driver)
            cal_net_auth_page.login('blah', 'blah')
            cal_net_auth_page.wait_until(timeout) { cal_net_auth_page.password.blank? }
            dashboard_page = CalCentralPages::MyDashboardPage.new(@driver)
            dashboard_page.load_page
            dashboard_page.wait_for_expected_title?
          end
        end
      end

      context 'when an unauthorized user' do
        before(:example) do
          splash_page = CalCentralPages::SplashPage.new(@driver)
          splash_page.load_page
          splash_page.basic_auth '61889'
          @driver.get("#{WebDriverUtils.base_url}/ccadmin")
        end
        context 'enters unauthorized re-auth credentials' do
          it 'redirects the user to My Dashboard' do
            cal_net_auth_page = CalNetAuthPage.new(@driver)
            cal_net_auth_page.login(UserUtils.oski_username, UserUtils.oski_password)
            dashboard_page = CalCentralPages::MyDashboardPage.new(@driver)
            dashboard_page.wait_for_expected_title?
          end
        end
        context 'enters invalid re-auth credentials' do
          it 'blocks access to CC admin' do
            cal_net_auth_page = CalNetAuthPage.new(@driver)
            cal_net_auth_page.login('blah', 'blah')
            cal_net_auth_page.wait_until(timeout) { cal_net_auth_page.password.blank? }
            dashboard_page = CalCentralPages::MyDashboardPage.new(@driver)
            dashboard_page.load_page
            dashboard_page.wait_for_expected_title?
          end
        end
      end
    end
  end
end
