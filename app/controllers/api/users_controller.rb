class Api::UsersController < ApplicationController
  include ApiHelper

  def create
    @user = User.new(user_params)
    if @user.save
      respond_to do |format|
        format.json { render json: @user }
      end
    else
      respond_bad_json('Unable to save user',400)
    end
  end

  def sign_in
    user = User.find_by_email(params[:user][:email])
    if user && user.authenticate(params[:user][:password])
      respond_to do |format|
        format.json { render json: user}
      end
    else
      respond_bad_json('Unable to sign in user',401)
    end
  end

  private
  def user_params
    params.require(:user).permit(:name,:email,:password,
                                 :password_confirmation)
  end
end
