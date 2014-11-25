class UsersController < ApplicationController

  def create
    @user = User.new(user_params)
    if @user.save
      respond_to do |format|
        format.json { render json: @user }
      end
    else
      respond_to do |format|
        format.json {render json: {message: 'Unable to save user'}, status: 401}
        end
    end
  end

  private
  def user_params
    params.require(:user).permit(:name,:email,:password,
                                 :password_confirmation)
  end
end
