describe 'My Finances landing page', :testui => true do

  if ENV["UI_TEST"] && Settings.ui_selenium.layer != 'production'

    before(:all) do
      @driver = WebDriverUtils.launch_browser
    end

    after(:all) do
      WebDriverUtils.quit_browser(@driver)
    end

    before(:context) do
      # Log into Production CalNet, since a couple links require Prod authentication
      @driver.get("#{Settings.cas_server}")
      @cal_net_prod_page = CalNetAuthPage.new(@driver)
      @cal_net_prod_page.login(UserUtils.oski_username, UserUtils.oski_password)
      splash_page = CalCentralPages::SplashPage.new(@driver)
      splash_page.load_page
      splash_page.click_sign_in_button
      @cal_net_page = CalNetAuthPage.new(@driver)
      @cal_net_page.login(UserUtils.oski_username, UserUtils.oski_password)
      @my_finances_page = CalCentralPages::MyFinancesPages::MyFinancesLandingPage.new(@driver)
      @my_finances_page.load_page
      @my_finances_page.billing_summary_list_element.when_visible(timeout=WebDriverUtils.page_load_timeout)
      @my_finances_page.fin_resources_list_element.when_visible(timeout)
    end

    context 'Billing Summary card' do
      it 'includes the heading Billing Summary' do
        expect(@my_finances_page.billing_summary_heading?).to be true
      end
      it 'shows CARS account balance amount' do
        expect(@my_finances_page.account_balance_element?).to be true
      end
      it 'shows CARS amount due now' do
        expect(@my_finances_page.amt_due_now_element?).to be true
      end
      it 'allows a user to show or hide the last statement balance' do
        @my_finances_page.show_last_statement_bal
        @my_finances_page.hide_last_statement_bal
      end
      it 'includes a link to view last statements' do
        @my_finances_page.show_last_statement_bal
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.view_statements_link_element, 'BearFacts | ')).to be true
      end
      it 'includes a link to make a payment for non-zero balances' do
        unless @my_finances_page.account_balance_element == '  $ 0.00'
          expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.make_payment_link_element, 'CARS Payment Options')).to be true
        end
      end
    end

    context 'Cal 1 Card card' do
      it 'includes a link to Cal 1 Card' do
        WebDriverUtils.verify_external_link(@driver, @my_finances_page.cal_1_card_link_element, 'Cal 1 Card: Home')
      end
      it 'includes a link to Cal Dining' do
        WebDriverUtils.verify_external_link(@driver, @my_finances_page.cal_dining_link_element, 'Caldining')
      end
    end

    context 'Financial Resources card' do
      it 'includes the heading Financial Resources' do
        expect(@my_finances_page.fin_resources_heading?).to be true
      end

      # Billing & Payments

      it 'includes a link to Billing Services' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.student_billing_svcs_link_element, 'Student Billing Services, University of California, Berkeley')).to be true
      end
      it 'includes a link to "How does my SHIP Waiver affect my billing?"' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.ship_waiver_link_element, 'How does my SHIP Waiver affect my billing? | Cal Student Central'))
      end
      it 'includes a link to e-bills' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.ebills_link_element, 'BearFacts | ')).to be true
      end
      it 'includes a link to Payment Options' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.payment_options_link_element, 'CARS Payment Options')).to be true
      end
      it 'includes a link to Registration Fees' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.reg_fees_link_element, 'Registration Fees - Office Of The Registrar')).to be true
      end
      it 'includes a link to Tax 1098-T Form' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.tax_1098t_form_link_element, 'Taxpayer Relief Act of 1997')).to be true
      end

      # Financial Assistance

      it 'includes a link to FAFSA' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.fafsa_link_element, 'Home - FAFSA on the Web - Federal Student Aid')).to be true
      end
      it 'includes a link to Financial Aid & Scholarships Office' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.fin_aid_scholarships_link_element, 'Financial Aid and Scholarships | UC Berkeley')).to be true
      end
      it 'includes a link to Graduate Financial Support' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.grad_fin_support_link_element, 'Financial Support | Berkeley Graduate Division')).to be true
      end
      it 'includes a link to Loan Repayment Calculator' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.loan_replay_calc_link_element, 'StudentLoans.gov'))
      end
      it 'includes a link to MyFinAid' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.my_fin_aid_link_element, 'UC Berkeley Financial Aid Web Self Service')).to be true
      end
      it 'includes a link to Student Budgets' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.student_budgets_link_element, 'Cost of Attendance | Financial Aid and Scholarships | UC Berkeley')).to be true
      end
      it 'includes a link to Work Study' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.work_study_link_element, 'Work-Study | Financial Aid and Scholarships | UC Berkeley')).to be true
      end

      # Leaving Cal?

      it 'includes a link to Have a loan?' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.have_loan_link_element, 'Exit Loan Counseling')).to be true
      end
      it 'includes a link to Withdrawing or Canceling?' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.withdraw_cancel_link_element, 'Cancellation,  Withdrawal and Readmission - Office Of The Registrar')).to be true
      end

      # Summer Programs

      it 'includes a link to Schedule & Deadlines' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.sched_and_dead_link_element, 'Schedule | Berkeley Summer Sessions')).to be true
      end
      it 'includes a link to Summer Session' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.summer_session_link_element, 'Berkeley Summer Sessions |')).to be true
      end

      # Your Questions Answered Here

      it 'includes a link to Cal Student Central' do
        expect(WebDriverUtils.verify_external_link(@driver, @my_finances_page.cal_student_central_link_element, 'Welcome! | Cal Student Central')).to be true
      end

    end
  end
end
