module CommissionHelper


  def calculate_our_earning_store(net_amount)

    net_amount * 0.1

  end

  def calculate_our_earning_driver(net_amount)

    if net_amount <= 10

      net_amount * 0.25

    elsif net_amount > 10 && net_amount <= 100

      net_amount * 0.15

    else

      net_amount * 0.10

    end

  end




end