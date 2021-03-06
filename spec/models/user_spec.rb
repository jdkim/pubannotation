require 'spec_helper'

describe User do
  describe 'scope except_current_user' do
    before do
      @current_user = FactoryGirl.create(:user)
      @anothers_user = FactoryGirl.create(:user)
      @users = User.except_current_user(@current_user)
    end
    
    it 'should include not current_user' do
      @users.should include(@anothers_user)
    end
    
    it 'should not include current_user' do
      @users.should_not include(@current_user)
    end
  end
  
  describe 'scope :except_project_associate_maintainers' do
    before do
      @project = FactoryGirl.create(:project)
      @associate_maintainer_user = FactoryGirl.create(:user)
      @not_associate_user = FactoryGirl.create(:user)
    end
    
    context 'when associate_maintainers present' do
      before do
        FactoryGirl.create(:associate_maintainer, :project => @project, :user => @associate_maintainer_user)
        @users = User.except_project_associate_maintainers(@project.id)
      end
      
      it 'should include not associate maintainer user' do
        @users.should include(@not_associate_user)
      end
      
      it 'should not include associate maintainer user' do
        @users.should_not include(@associate_maintainer_user)
      end
    end
    
    context 'when associate_maintainers present' do
      before do
        @users = User.except_project_associate_maintainers(@project.id)
      end
      
      it 'should include all users' do
        @users.should =~ User.all
      end
    end
  end
  
  describe 'has_many :associate_maintainers' do
    before do
      @project = FactoryGirl.create(:project, :user => FactoryGirl.create(:user))
      @user = FactoryGirl.create(:user)
      @associate_maintainer_1 = FactoryGirl.create(:associate_maintainer, 
        :user => @user,
        :project => @project)
      @associate_maintainer_2 = FactoryGirl.create(:associate_maintainer, 
        :user => @user,
        :project => @project)      
    end
    
    it 'should be present' do
      @user.associate_maintainers.should be_present
    end
    
    it 'should include associate_maineiners' do
      @user.associate_maintainers.should =~ [@associate_maintainer_1, @associate_maintainer_2]
    end
    
    it 'should destory all associate maintainers when detroyed' do
      @user.destroy
      AssociateMaintainer.all.should be_blank
    end
  end

  describe 'has_many projects' do
    before do
      @user = FactoryGirl.create(:user)
      @project_1 = FactoryGirl.create(:project, :user => @user)
      @project_2 = FactoryGirl.create(:project, :user => @user)
    end
    
    it 'should be present' do
      @user.projects.should be_present
    end
    
    it 'should include projects' do
      @user.projects.should =~ [@project_1, @project_2]
    end
  end
  
  describe 'has_many :associate_maintaiain_projecs' do
    before do
      @project_1 = FactoryGirl.create(:project, :user => FactoryGirl.create(:user))
      @user = FactoryGirl.create(:user)
      @associate_maintainer_1 = FactoryGirl.create(:associate_maintainer, 
        :user => @user,
        :project => @project_1)
      @project_2 = FactoryGirl.create(:project, :user => FactoryGirl.create(:user))
      @associate_maintainer_2 = FactoryGirl.create(:associate_maintainer, 
        :user => @user,
        :project => @project_2)      
    end
    
    it 'should be present' do
      @user.associate_maintaiain_projects.should be_present
    end
    
    it 'should include associate_maineiners' do
      @user.associate_maintaiain_projects.should =~ [@project_1, @project_2]
    end
  end
  
  describe 'self.find_first_by_auth_conditions' do
    before do
      @user_name = 'user_name'
      @user = FactoryGirl.create(:user, :username => @user_name)
    end

    context 'when conditions include login' do
      it 'should return user who matches login username' do
        User.find_first_by_auth_conditions({:login => @user_name}).should eql(@user)
      end
    end

    context 'when conditions does not include user name' do
      it '' do
        User.find_first_by_auth_conditions({:id => @user.id}).should eql(@user)
      end
    end
  end
end