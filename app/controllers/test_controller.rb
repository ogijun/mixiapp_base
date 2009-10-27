class TestController < ApplicationController
  transit_sid :mobile
  mobile_filter :hankaku => true
  before_filter :validate_session
  after_filter :adjust_session
  after_filter :set_header

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
  end
end
