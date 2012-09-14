require 'spec_helper'

describe SurveysController do
  render_views

  context "GET 'index'" do
    it "assigns the surveys instance variable" do
      get :index
      assigns(:surveys).should_not be_nil
    end

    it "responds with the index page" do
      get :index
      response.should be_ok
      response.should render_template(:index)
    end

    context "when filtering" do
      before(:each) do
        Survey.delete_all
      end

      context "when CSO admin is logged in" do
        before(:each) do
          sign_in_as('cso_admin')
          @unpublished_survey = FactoryGirl.create(:survey, :published => false)
          @published_survey = FactoryGirl.create(:survey, :published => true)
        end

        it "shows all published surveys if filter is published" do
          get :index, :published => true
          response.should be_ok
          assigns(:surveys).should include @published_survey
          assigns(:surveys).should_not include @unpublished_survey
        end

        it "shows all unpublished surveys if filter is unpublished" do
          get :index, :published => false
          response.should be_ok
          assigns(:surveys).should include @unpublished_survey
          assigns(:surveys).should_not include @published_survey
        end

        it "shows all surveys if filter is not specified" do
          get :index
          response.should be_ok
          assigns(:surveys).should include @unpublished_survey
          assigns(:surveys).should include @published_survey
        end
      end

      context "when a User is logged in" do
        it "shows only published surveys from the user's organization" do
          sign_in_as('user')
          session[:user_info][:org_id] = 123
          survey = FactoryGirl.create(:survey, :owner_org_id => 123, :published => true)
          another_survey = FactoryGirl.create(:survey, :owner_org_id => 125, :published => true)
          get :index
          response.should be_ok
          assigns(:surveys).should eq [survey]
        end
      end
    end
  end

  context "DELETE 'destroy'" do
    let!(:survey) { FactoryGirl.create(:survey) }
    before(:each) do
      sign_in_as('cso_admin')
    end

    it "requires cso_admin for Deleting a survey" do
      sign_in_as('user')
      delete :destroy, :id => survey.id
      response.should redirect_to(surveys_path)
      flash[:error].should_not be_empty
    end

    it "deletes a survey" do
      expect { delete :destroy, :id => survey.id }.to change { Survey.count }.by(-1)
      flash[:notice].should_not be_nil
    end

    it "redirects to the survey index page" do
      delete :destroy, :id => survey.id
      response.should redirect_to surveys_path
    end
  end

  context "GET 'new" do

    before(:each) do
      sign_in_as('cso_admin')
    end

    it "requires cso_admin for creating a survey" do
      sign_in_as('user')
      get :new
      response.should redirect_to(surveys_path)
      flash[:error].should_not be_empty
    end

    it "assigns the survey instance variable" do
      get :new
      assigns(:survey).should_not be_nil
    end
  end

  context "POST 'create'" do
    before(:each) do
      sign_in_as('cso_admin')
      session[:user_info][:org_id] = 123
      @survey_attributes = FactoryGirl.attributes_for(:survey)
    end

    it "requires cso_admin for creating a survey" do
      sign_in_as('user')
      post :create, :survey => @survey_attributes
      response.should redirect_to(surveys_path)
      flash[:error].should_not be_empty
    end

    context "when save is unsuccessful" do
      it "redirects to the surveys build path" do
        post :create, :survey => @survey_attributes
        created_survey = Survey.find_last_by_name(@survey_attributes[:name])
        response.should redirect_to(surveys_build_path(:id => created_survey.id))
        flash[:notice].should_not be_nil
      end

      it "creates a survey" do
        expect { post :create,:survey => @survey_attributes }.to change { Survey.count }.by(1)
      end

      it "assigns the organization id of the current user to the survey" do
        post :create, :survey => @survey_attributes
        created_survey = Survey.find_last_by_name(@survey_attributes[:name])
        created_survey.owner_org_id.should == session[:user_info][:org_id]
      end
    end

    context "when save is unsuccessful" do
      it "renders the new page" do
        post :create, :surveys => { :name => "" }
        response.should be_ok
        response.should render_template(:new)
      end
    end
  end

  context "GET 'build'" do
    before(:each) do
      sign_in_as('cso_admin')
      @survey = FactoryGirl.create(:survey)
    end

    it "requires cso_admin for building a survey" do
      pending
      sign_in_as('user')
      get :build, :id => @survey.id
      response.should redirect_to(surveys_path)
      flash[:error].should_not be_empty
    end

    it "renders the 'build' template" do
      get :build, :id => @survey.id
      response.should render_template(:build)
    end
  end

  context "PUT 'publish'" do
    before(:each) do
      sign_in_as('cso_admin')
      @survey = FactoryGirl.create(:survey)
    end

    it "requires cso_admin for publishing a survey" do
      sign_in_as('user')
      put :publish, :survey_id => @survey.id
      response.should redirect_to(surveys_path)
      flash[:error].should_not be_empty
    end

    it "changes the status of a survey from unpublished to published" do
      put :publish, :survey_id => @survey.id
      response.should redirect_to(surveys_path)
      flash[:notice].should_not be_nil
      Survey.find(@survey.id).should be_published
    end
  end

  context "PUT 'unpublish'" do
    before(:each) do
      sign_in_as('cso_admin')
      @survey = FactoryGirl.create(:survey, :published => true)
    end

    it "requires cso_admin for unpublishing a survey" do
      sign_in_as('user')
      put :unpublish, :survey_id => @survey.id
      response.should redirect_to(surveys_path)
      flash[:error].should_not be_empty
    end

    it "changes the status of a survey from published to unpublished" do
      put :unpublish, :survey_id => @survey.id
      response.should redirect_to(surveys_path)
      flash[:notice].should_not be_nil
      Survey.find(@survey.id).should_not be_published
    end
  end

  context "When sharing the survey" do
    it "renders the share page with a list of organizations except survey's owner organization" do
      sign_in_as('cso_admin')
      session[:user_info][:organizations] = [{:id => 123, :name => "foo"}, {:id => 12, :name => "nid"}]
      survey = FactoryGirl.create(:survey, :owner_org_id => 12)

      get :share, :survey_id => survey.id
      response.should be_ok
      response.should render_template :share
      assigns(:organizations).should == [{"id" => 123, "name" => "foo"}]
    end
  end
end
