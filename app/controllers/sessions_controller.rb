class SessionsController < Devise::SessionsController
  respond_to :json

  before_action :verify_authentication, only: [:show]

  def show
    render json: { :user => { id: current_user.id, email: current_user.email } }
  end

  def hoge
    a = 1  
    b = 1
    c = 3
    d = a

    e = 1 if b 
    g = 1 unless c
  end


  def hoge2
    var = "aaaaa"  
    var = "bbbbb"  
    var2 = "ccccc"  
    var2 = "ddddd"  
  end  

  def verify_authentication
    unless user_signed_in?
      render json: { error: 'forbidden' }, status: 403
      return false
    end
  end
end