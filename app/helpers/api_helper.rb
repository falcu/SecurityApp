module ApiHelper

  def respond_bad_json(message,status)
    respond_to do |format|
      format.json {render json: {error: message}, status: status}
    end
  end

end
