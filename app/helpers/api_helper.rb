module ApiHelper

  def render_json(json_args,status)
    respond_to do |format|
      format.json {render json: json_args, status: status}
    end
  end

end
