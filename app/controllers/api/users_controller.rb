class Api::UsersController < ApplicationController
  include ApiHelper

  def create
    @user = User.new(user_params)
    add_device
    if @user.save
      render_json(user_to_json, 200)
    else
      render_json({error: "Unable to save user"}, 400)
    end
  end

  def sign_in
    @user = User.find_by_email(params[:user][:email])

    if authenticate_user
      add_device
      render_json(user_to_json, 200)
    else
      render_json({error: "Unable to sign in user"}, 401)
    end
  end

  def create_or_sign_in
      @user = User.find_by_email(params[:user][:email])
    if authenticate_user
      add_device
      render_json(user_to_json, 200)
    else
      create
    end
  end

  private
  def user_params
    params.require(:user).permit(:name, :email, :password,
                                 :password_confirmation)
  end

  private
  def device_params
    params.require(:user).require(:device).permit(:registration_id)
  end

  private
  def add_device
    if params[:user][:device] && Device.where("user_id = ? AND registration_id = ?", @user.id, params[:user][:device][:registration_id]).first.nil?
      @user.devices << Device.new(device_params)
      @user.save
    end
  end

  private
  def user_to_json
    {:user => {id: @user.id, name: @user.name, email: @user.email, token: @user.token}}
  end

  private
  def authenticate_user
    @user && @user.authenticate(params[:user][:password])

  end
end
