class Api::UsersController < ApplicationController
  include ApiHelper

  def create
    @user = User.new(user_params)
    if @user.save
      respond_to do |format|
        format.json { render json: @user }
      end
    else
      respond_bad_json('Unable to save user')
    end
  end

  private
  def user_params
    params.require(:user).permit(:name,:email,:password,
                                 :password_confirmation)
  end
end
