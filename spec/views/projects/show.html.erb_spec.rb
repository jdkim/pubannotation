# encoding: utf-8
require 'spec_helper'

describe "projects/show.html.erb" do
  before do
    @project_user = FactoryGirl.create(:user)
    #@associate_maintainer_user = FactoryGirl.create(:user)
    @project = FactoryGirl.create(:project, :user => @project_user, :rdfwriter => '', :xmlwriter => '', :bionlpwriter => '')
    #@associate_maintainer = FactoryGirl.create(:associate_maintainer, :project => @project, :user => @associate_maintainer_user)
    assign :project, @project
    assign :pmdocs, []
    assign :pmcdocs, []
    view.stub(:will_paginate).and_return(nil)
  end
  
  describe 'edit delete link' do
    context 'when user_signed_in? == true' do
      before do
        view.stub(:user_signed_in?).and_return(true)
        view.stub(:current_user).and_return(nil)
      end
      
      describe 'edit link' do
        context 'when updatable_for? == true' do
          before do
            @project.stub(:updatable_for?).and_return(true)            
            render
          end
          
          it 'should render edit link' do
            rendered.should have_selector :a, :href => edit_project_path(@project.name)
          end
        end

        context 'when updatable_for? == false' do
          before do
            @project.stub(:updatable_for?).and_return(false)            
            render
          end
          
          it 'should not render edit link' do
            rendered.should_not have_selector :a, :href => edit_project_path(@project.name)
          end
        end
      end
      
      describe 'delete link' do
        context 'when destroyable_for? == true' do
          before do
            @project.stub(:destroyable_for?).and_return(true)            
            render
          end
          
          it 'should render edit link' do
            rendered.should have_selector :a, :href => @project.name, 'data-method' => 'delete'
          end
        end

        context 'when destroyable_for? == false' do
          before do
            @project.stub(:destroyable_for?).and_return(false)            
            render
          end
          
          it 'should not render edit link' do
            rendered.should_not have_selector :a, :href => @project.name, 'data-method' => 'delete'
          end
        end
      end
    end
  end
end