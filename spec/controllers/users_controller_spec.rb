# encoding: utf-8
require 'spec_helper'

describe UsersController do
  describe 'autocomplete_username' do
    before do
      @user = FactoryGirl.create(:user, :username => 'user1')
      @current_user = FactoryGirl.create(:user)
      current_user_stub(@current_user)
      @project = FactoryGirl.create(:project)
    end
    
    context 'when project_id blank' do
      before do
        get :autocomplete_username, :term => @user.username
      end
      
      it 'should render uses username as json' do
        response.body.should eql("[\"user1\"]")
      end
    end

    context 'when project_id present' do
      before do
        get :autocomplete_username, :project_id => @project.id, :term => @user.username
      end
      
      it 'should render uses username as json' do
        response.body.should eql("[\"user1\"]")
      end
    end
  end
end