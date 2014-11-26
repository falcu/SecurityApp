class Api::GroupsController < ApiController

  def create
    @group = Group.new(group_params)
    if @group.save
      respond_to do |format|
        format.json { render json: @group }
      end
    else
      respond_to do |format|
        format.json {render json: {message: 'Unable to create group'}, status: 401}
      end
    end
  end

  private
  def group_params
    params.require(:group).permit(:name)
  end
end
