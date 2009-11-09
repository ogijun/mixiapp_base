class TestController < ApplicationController
  before_filter :validate_session

  def profile
  end
  def friends
  end
  def script
  end
  def script2
    render :layout => false
  end
  def activity
    render :layout => false
  end
end
