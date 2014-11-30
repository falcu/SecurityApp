module ApiHelper
  def respond_bad_json(message)
    respond_to do |format|
      format.json {render json: {error: message}, status: 401}
    end
  end
end
