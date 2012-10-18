class ResponsesController < ApplicationController
  load_and_authorize_resource :survey
  load_and_authorize_resource :through => :survey

  before_filter :survey_published
  
  def index
    @responses = @responses.paginate(:page => params[:page], :per_page => 10)
  end

  def create
    response = ResponseDecorator.new(Response.new)
    response.set(params[:survey_id], current_user, current_user_org)
    survey = Survey.find(params[:survey_id])
    survey.questions.each { |question| response.answers << Answer.new(:question_id => question.id) }
    response.save(:validate => false)
    redirect_to edit_survey_response_path(:id => response.id), :notice => t("responses.new.response_created")
  end

  def edit
    @survey = Survey.find(params[:survey_id])
    @response = ResponseDecorator.find(params[:id])
    @response.answers.select!{|answer| answer.question.first_level? }
  end

  def update
    @response = ResponseDecorator.find(params[:id])
    if @response.update_attributes(params[:response])
      redirect_to survey_responses_path, :notice => "Successfully updated"
    else
      flash[:error] = "Error"
      render :edit
    end
  end

  def complete
    @response = ResponseDecorator.find(params[:id])
    @response.mark_complete
    if @response.update_attributes(params[:response])
      redirect_to survey_responses_path(@response.survey_id), :notice => "Successfully updated"
    else
      @response.mark_incomplete
      flash[:error] = "Error"
      render :edit
    end
  end

  private

  def survey_published
    survey = Survey.find(params[:survey_id])
    unless survey.published
      flash[:error] = t "flash.reponse_to_unpublished_survey", :survey_name => survey.name
      redirect_to surveys_path
    end
  end
end
